(function ($) {
        // hijack IPython's methods of all CodeCells with the required metadata
    if (!window.Homework) {
        var get_text = IPython.CodeCell.prototype.get_text
        IPython.CodeCell.prototype.get_text = function () {
            if (this.metadata && typeof(this.metadata.question) !== "undefined") {
                // TODO: Include problem set number, user id
                return "using Homework \n" +
                "Homework.evaluate(" + this.metadata.question + ", " + get_text.call(this) + ")"
            } else {
                return get_text.call(this)
            }
        }

        var delete_cell = IPython.Notebook.prototype.delete_cell
        IPython.Notebook.prototype.delete_cell = function (index) {
            console.log(index)
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
        }
    }
})(jQuery)
