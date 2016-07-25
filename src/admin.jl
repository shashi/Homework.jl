using DataFrames

include("coloredtable.jl")

function manage_problemset()
    script("IPython.notebook.metadata.mode = \"create\"; Homework.refresh_messages()")
end

function new_question(metadata_json, answer)

    metadata = JSON.parse(metadata_json)

    meta = Signal(Any, Dict())
    question = metadata["question"]

    display(set_metadata(question, Dict("answer" => JSON.json(encode(metadata, answer)))))
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

function clear_admin_metadata()
    global_config["mode"] = "answering"
    script("Homework.clear_admin_metadata(); Homework.refresh_messages()") |> display
    display(Html("You can try out the answer cells as if you were the student now. Next run Homework.clear_answers() to remove the answers."))
end

function clear_answers()
    script("Homework.clear_answers(); Homework.refresh_messages()") |> display
    display(Html("All the answers should be cleared now, delete this cell and the cell containing Homework.manage_problemset, save the notebook and it will be good to distribute for answering."))
end

function progress(all=(get(global_config, "mode",  "") == "create"))
    mode = all ? "report" : "myreport"
    res = get(string(strip(get(global_config, "host", "https://juliabox.com"), ['/']), "/jboxplugin/hw/");
                    query = Dict("mode" => mode,
                    "params" => JSON.json(Dict(
                        "course" => global_config["course"],
                        "problemset" => global_config["problemset"]))),
                headers = Dict("Cookie" => global_config["cookie"]))

    if statuscode(res) == 200
        result = Requests.json(res)
        if result["code"] != 0
            display(Html("<div class='alert alert-danger'> Something went wrong while getting the report </div>"))
            dump(result)
        else
            return @manipulate for report=Dict("Score" => "score", "Incorrect attempts" => "attempts")
                make_score_dataframe(result["data"], report) |>
                    x -> report == "score" ? color_progress(x) : x
            end
        end
    else
        display(MIME"text/html"(), "<div class='alert alert-danger'> There was an error contacting the homework server </div>")
    end
end
