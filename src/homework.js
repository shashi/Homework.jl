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

        window.Homework = {
            config: {}
        }
    }
})(jQuery)
