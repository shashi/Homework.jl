
function new_problemset()
    script("Homework.mode = \"create\"; Homework.refresh_messages()")
end

function new_question(config_json, metadata_json, cookie, answer)

    metadata = JSON.parse(metadata_json)

    meta = Input{Any}(Dict())
    question = metadata["question"]

    display(set_metadata(question, ["ans" => JSON.json(encode(metadata, answer))]))
    display(set_metadata(question,
      alert("info", string("<span class='icon-info'></span> ",
        "Will commit last result as the answer to question ",
        question))))

    # return the answer itself for consistency
    answer
end

function save_problemset()
    script("Homework.create_problemset(); Homework.refresh_messages()") |> display
end

function clear_answers()
    script("Homework.clear_answers(); Homework.refresh_messages()") |> display
    display(Html("All the answers should be cleared now, delete this cell and the cell containing Homework.new_problemset, save the notebook and it will be good to distribute for answering."))
end
