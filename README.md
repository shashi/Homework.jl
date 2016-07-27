# Homework

### Creating a problemset

Open a new julia notebook on JuliaBox and click on Edit -> Edit Notebook Metadata.  Then add the following JSON:

```json
  "homework": {
    "course": "<name of your course>",
    "problemset": "<name of this problemset>",
    "mode": "create"
  }
```

Evaluate `using Homework` in a cell.  You can frame a question using markdown (see the drop down in the toolbar).  Enter the answer expression in a cell below.  Click on the 'Cell Toolbar' drop down and click 'Edit Metadata'.  Click the 'Edit Metadata' button for the answer cell and insert the following JSON:

```json
{
  "question": "<an id for this question>"
}
```

Evaluate the cell.  You have now created an answer field.  Similarly you can create more questions and prepare a problem set.

In order to create a notebook file that you can send to your students you would need to first save the answers to the JuliaBox database.  You can do so with a call to `Homework.save_problemset()`.  You can now clear the answers by saying `Homework.clear_answers()`.  You might want to create a copy of the notebook before clearing the answers.  The notebook is now ready to be sent to your students.

### Answering a problemset

Enter your answer expression in the cell below the question and evaluate it.  A submit button should appear.  Clicking on the submit button checks for correctness and also records the number of attempts made.

To see a summary of your scores evaluate `Homework.progress()`.

### Getting student scores

Running `Homework.progress()` as a creator of a problemset gives you the results for all students.
