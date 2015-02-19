(function ($) {
        // hijack IPython's methods of all CodeCells with the required metadata
    if (!window.Homework) {
        var get_text = IPython.CodeCell.prototype.get_text
        IPython.CodeCell.prototype.get_text = function () {
            if (this.metadata && typeof(this.metadata.question) !== "undefined") {
                // TODO: Include problem set number, user id
                return 'Homework.attempt_prompt(' + [ JSON.stringify(JSON.stringify(Homework.config)),
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
                console.log(data)
                var cls = ".signal-" + data.metadata.comm_id
                data.html = $(cls).eq(0).html()
                console.log(data.html)
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
            var meta = cell.metadata,
                msg = meta.msg || "<span class='icon-terminal'></span> &nbsp; Code your answer here, run it, and then make an attempt. <span style='float: right'>",
                score = meta.score || 0,
                max_score = meta.max_score || 0,
                attempts = meta.attempts || 0,
                max_attempts = meta.max_attempts

            msg += "<span style='float: right' class='label label-info'> Score: <b>" + score + " / " + max_score + "</b>"
            if (max_attempts != 0) {
                msg += " &middot; Attempts: <b>" + attempts + " / " + max_attempts + "</b>"
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

        window.Homework = {
            config: {},
            set_meta: set_meta,
            mount_message: mount_message
        }
    }


    function show_messages() {
        var i = 0
        var cell = IPython.notebook.get_cell(i)
        while(cell !== null) {
            if (cell.metadata && typeof(cell.metadata.question) !== "undefined") {
                var q = cell.metadata.question
                mount_message(cell)
            }
            cell = IPython.notebook.get_cell(i)
            i+=1
        }
    }

    var timer = setTimeout(show_messages, 500)

    $([IPython.events]).on('notebook_loaded.Notebook', show_messages)
    $([IPython.events]).on('create.Cell', show_messages) 

})(jQuery)
