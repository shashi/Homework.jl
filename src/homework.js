(function ($) {
        // hijack IPython's methods of all CodeCells with the required metadata
    if (!window.Homework) {
        var get_text = IPython.CodeCell.prototype.get_text
        IPython.CodeCell.prototype.get_text = function () {
            if (this.metadata && typeof(this.metadata.question) !== "undefined") {
                // TODO: Include problem set number, user id
                return "Homework.evaluate(" + [ '"' + Homework.problem_set +'"',
                                         '"' + this.metadata.question + '"',
                                         '"' + Homework.user + '"',
                                         "(" + get_text.call(this) +")"
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

        window.Homework = {
            user: "",
            problem_set: ""
        }

        function set_juliabox_user_id() {
            var sessname = /sessname=([^;]+);/.exec(document.cookie);
            if (sessname) {
                window.Homework.user = sessname[1]
            }
        }

        // try to set the juliabox sessname as the user id.
        set_juliabox_user_id()
    }
})(jQuery)
