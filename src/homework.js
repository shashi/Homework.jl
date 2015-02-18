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

        function set_meta(question, key, value) {
            get_question(question).metadata[key] = value
        }

        window.Homework = {
            config: {},
            set_meta: set_meta
        }
    }

    function make_message(metadata) {
        var msg = "<div class='hw-msg' style='color: #888; background: #efefef; font-size: 0.8em; padding: 0.5em 0.5em 0.5em 0.5em'>" +
                  "<span class='icon-info-sign'></span> Code your answer here, run it, and then make an attempt. <span style='float: right'>"
        if (metadata.score) {
           msg += " Max score: <b>" + metadata.score + "</b>"
        }
        if (metadata.attempts == 0) {
           msg += " &middot; Attempts allowed: <b>infinite!</b>"
        } else if (typeof(metadata.attempts) == "number") {
           msg += " &middot; Attempts allowed: <b>" + metadata.attempts + "</b>"
        }
        return msg + "</span></div>"
    }

    function show_messages() {
        var i = 0
        var cell = IPython.notebook.get_cell(i)
        while(cell !== null) {
            if (cell.metadata && typeof(cell.metadata.question) !== "undefined") {
                var el = cell.element
                var q = cell.metadata.question
                $(el).find(".hw-msg").remove()
                $(el).find(".input_area").append(make_message(cell.metadata))
            }
            cell = IPython.notebook.get_cell(i)
            i+=1
        }
    }

    var timer = setTimeout(show_messages, 3000)

    $([IPython.events]).on('notebook_loaded.Notebook', show_messages)
    $([IPython.events]).on('create.Cell', show_messages) 

})(jQuery)
