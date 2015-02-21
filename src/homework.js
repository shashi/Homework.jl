(function ($) {
        // hijack IPython's methods of all CodeCells with the required metadata
    if (!window.Homework) {
        var get_text = IPython.CodeCell.prototype.get_text
        IPython.CodeCell.prototype.get_text = function () {
            if (this.metadata && typeof(this.metadata.question) !== "undefined") {
                // TODO: Include problem set number, user id
                var fn = (Homework.mode === "create") ? "new_question" : "attempt_prompt";
                return 'Homework.' + fn + '(' + [ JSON.stringify(JSON.stringify(Homework.config)),
                                         JSON.stringify(JSON.stringify(this.metadata)),
                                         JSON.stringify(document.cookie),
                                         "begin " + get_text.call(this) +" end"
                                       ].join(", ") + ")"
            } else {
                return get_text.call(this)
            }
        }

        var cell_to_json = IPython.CodeCell.prototype.toJSON
        IPython.CodeCell.prototype.toJSON = function () {
            if (this.metadata && typeof(this.metadata.question) !== "undefined") {
                data = cell_to_json.call(this)
                data.input = get_text.call(this)
                return data
            } else {
                return cell_to_json.call(this)
            }
        }

        var rename_keys = IPython.OutputArea.prototype.rename_keys;
        IPython.OutputArea.prototype.rename_keys = function (data, key_map) {
            data = rename_keys(data, key_map)

            if (data.metadata && data.metadata.reactive) {
                var cls = ".signal-" + data.metadata.comm_id
                data.html = $(cls).eq(0).html()
            }
            return data
        }

        var delete_cell = IPython.Notebook.prototype.delete_cell
        IPython.Notebook.prototype.delete_cell = function (index) {
            var i = this.index_or_selected(index);
            var cell = this.get_selected_cell();
            if (cell.metadata && typeof(cell.metadata.question) !== "undefined") {
                alert("Cannot delete this cell. You need to code the answer to Question " + 
                        cell.metadata.question + " here.")
            } else {
                // go on and delete
                delete_cell.call(this, i)
            }
        }

        function get_question(q) {
            var i = 0
            var cell = IPython.notebook.get_cell(i)
            while(cell !== null) {
                if (cell.metadata && cell.metadata.question === q) {
                    return cell
                }
                cell = IPython.notebook.get_cell(i)
                i+=1
            }
            return null
        }

        function mount_message(cell) {
            if (!cell) { return }
            var meta = cell.metadata,
                msg = meta.msg || "<span class='icon-terminal'></span> &nbsp; Code your answer here. <span style='float: right'>",
                score = meta.score || 0,
                max_score = meta.max_score || 0,
                attempts = meta.attempts || 0,
                max_attempts = meta.max_attempts || 0

            msg += "<span style='float: right' class='label label-info'> Score: "
            if (Homework.mode === "answering") {
                msg += "<b>" + score + "</b> / <b>" + max_score + "</b>"
            } else if (Homework.mode === "create") {
                msg += "<b>" + max_score + "</b>"
            }

            msg += " &middot; Attempts: "
            if (Homework.mode === "answering") {
                msg += "<b>" + attempts + "</b>"
                if (max_attempts != 0) {
                    msg += " / <b>" + max_attempts + "</b>"
                }
            } else if (Homework.mode === "create") {
                msg += "<b>" + max_attempts + "</b>"
            }
            msg += "</span>"

            var level = meta.alert || "info"

            msg = "<div class='hw-msg alert alert-" + level + "' id='hw-msg-" + meta.question +
                   "' style='padding: 0.5em; margin: 0; border-radius: 0'>" +
                   msg + "</div>"

            $(cell.element).find(".hw-msg").remove()
            $(cell.element).find(".input_area").eq(0).append(msg)
        }

        function set_meta(question, extension) {
            console.log("set meta", question, extension)
            var cell = get_question(question)
            for (var key in extension) {
                if (extension.hasOwnProperty(key)) {
                    cell.metadata[key] = extension[key]
                }
            }
            mount_message(cell)
        }

        function get_question_cells() {
            var cell = IPython.notebook.get_cell(0),
                i = 0,
                cells = []
            while(cell !== null) {
                if (cell.metadata && typeof(cell.metadata.question) !== "undefined") {
                    var q = cell.metadata.question
                    cells.push(cell)
                }
                i+=1
                cell = IPython.notebook.get_cell(i)
            }
            return cells
        }

        function hw_create(host, course, s, f) {
            if(!s) {
                s = function(result){
                    if(result.code == 0) {
                        IPython.dialog.modal({
                            title: 'Problemset created',
                            body: "The problem set was created. Now run <code>Homework.clear_answers()</code> to get the notebook ready for distribution."
                        })
                    }
                    else {
                        IPython.dialog.modal({
                            title: 'Problemset NOT created',
                            body: "Non-zero result code. There was a problem saving the problem set!"
                        })
                    }
                };
            };
            if(!f) {
                f = function() {
                        IPython.dialog.modal({
                            title: 'Failure',
                            body: "Failed to create problem set. Are you sure you have permission to edit the course? Unexpected server error."
                        })
                };
            };
            console.log({
                'mode': 'create',
                'params': JSON.stringify(course)
            })
            $.ajax({
                url: host + '/hw/',
                method: 'POST',
                data: {
                    'mode': 'create',
                    'params': JSON.stringify(course)
                },
                success: s,
                failure: f
            })
        }

        function create_problemset(config) {

            var cells = get_question_cells()
            config = config || Homework.config
            if (!config.admins) {
                alert("No administrators assigned for this set, add them in Homework.configure")
                return
            }

            if (!config.host) { config.host == "" }
            var questions = []
            for (var i=0, l=cells.length; i < l; i++) {
                questions.push({
                    id:    String(cells[i].metadata.question),
                    score: cells[i].metadata.max_score,
                    attempts: cells[i].metadata.max_attempts,
                    ans:   cells[i].metadata.answer
                })
            }

            var course = {
                 admins: config.admins,
                 id: config.course,
                 problemsets: [{
                     id: config.problemset,
                     questions: questions
                 }]
            }

            console.log(course)

            try {
                hw_create(config.host || "", course)
            } catch (e) {
                alert("An error occured. Problem set not saved!")
            }
       }

       function clear_answers() {
           var cells = get_question_cells()
           for (var i=0, l=cells.length; i < l; i++) {
               var cell = cells[i]
               delete cell.metadata.answer
               delete cell.metadata.msg
               delete cell.metadata.alert
               cell.clear_input()
               cell.clear_output()
           }
           Homework.mode = "answering"
           Homework.refresh_messages()
       }

        function refresh_messages(q) {
            _.map(q ? [get_question(q)] : get_question_cells(), mount_message)
        }

        $([IPython.events]).on('notebook_loaded.Notebook', refresh_messages)
        $([IPython.events]).on('create.Cell', refresh_messages)

       window.Homework = {
            config: {},
            mode: "answering",
            set_meta: set_meta,
            mount_message: mount_message,
            clear_answers: clear_answers,
            refresh_messages: refresh_messages,
            create_problemset: create_problemset
       }
    }

})(jQuery)
