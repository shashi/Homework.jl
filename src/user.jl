#
# This form maps JuliaBox ids to MIT email ids
#
function show_mit_form()
    display(MIME("text/html"), """<iframe src="https://docs.google.com/forms/d/1uPqGeJChe0FFOsuUkdeLVbgPo9LzQEbRnS0xIzE-VGo/viewform?embedded=true" width="720" height="570" frameborder="0" marginheight="0" marginwidth="0">Loading...</iframe>""")
end
#
# Save answer in a closure for the submit button event,
# make the button and display it. return the answer as is.
#
function attempt_prompt(metadata_json, answer)

    metadata = JSON.parse(metadata_json)

    metadata_channel = Input{Any}(Dict())

    question = metadata["question"]
    lift(metadata_channel, init=script("")) do x
        set_metadata(question, x)
    end |> display

    if !get(metadata, "finished", false)
        b = button("Submit »")
        display(b)

        lift(signal(b), init=nothing) do _
            evaluate(metadata, answer, metadata_channel)
        end
    end
    answer
end

#
# Evaluate an answer.
#

function evaluate(metadata, answer, meta)
    @assert haskey(metadata, "question")

    if !haskey(global_config, "host")
        global_config["host"] = "https://juliabox.org"
    end
    question_no = string(metadata["question"])

    @async push!(meta, alert("info", "Evaluating your answer..."))

    # The HTTP requests to evaluate answer goes here...
    # After the request, you can push the
    query_params = [
        "mode" => "submit",
        "params" => JSON.json([
            "course" => global_config["course"],
            "problemset" => global_config["problemset"],
            "question" => question_no,
            "answer" => JSON.json(encode(metadata, answer))
        ])
    ]

    response = nothing
    try
        response = get(string(strip(global_config["host"], ['/']), "/jboxplugin/hw/");
            query = query_params,
            headers = ["Cookie" => global_config["cookie"]])

    catch err
        open("homework_log.log", "a") do f
            bt = catch_backtrace()
            Base.show_backtrace(f, bt)
            println(f, err)
        end
    end


    try
        if response != nothing && statuscode(response) == 200
            result = Requests.json(response)
            if result["code"] != 0
                open("homework_log.log", "a") do f
                    println(f, "Code Non-zero")
                end
                @async push!(meta, alert("danger", "Something went wrong while verifying your code!"))
            else
                @async report_evaluation(result, metadata, meta)
            end
        else
            open("homework_log.log", "a") do f
                write(f, string(response))
            end
            @async push!(meta, alert("danger",
                "There was an unexpected error while accessing the homework server."))
        end

    catch err
        open("homework_log.log", "a") do f
            bt = catch_backtrace()
            Base.show_backtrace(f, bt)
            println(f, err)
        end
        @async push!(meta, alert("danger",
            "Something went wrong in Homework.jl"))
    end
    # return the answer itself for consistency
    answer
end

function report_evaluation(result, metadata, meta_channel)

    data = result["data"]
    status = data["status"]
    score = data["score"]
    attempts = data["attempts"]
    explanation = get(data, "explanation", nothing)
    data["max_attempts"] = data["max_attempts"] == 0 ? get(metadata, "max_attempts", 0) : data["max_attempts"]
    max_attempts = data["max_attempts"]
    max_score = data["max_score"]

    if status == 1
        msg = "<span class='icon-thumbs-up'></span> Your last attempt was <b>correct!</b>"

        if isa(explanation, String) && explanation != ""
            msg = msg*"<p style='font-size:0.9em'><br><em>Explanation:</em> $explanation</p>"
        end

        merge!(data,
            alert("success", msg))

        data["finished"] = true
    else
        if max_attempts != 0 && attempts > max_attempts
            msg = "<span class='icon-thumbs-down'></span> You <b>exceeded the maximum number of failed attempts</b> allowed for this question."
            data["finished"] = true
        else
            msg = "<span class='icon-eraser'></span> Wrong answer. <b>Try again.</b>"
        end

        merge!(data,
            alert("warning", msg,))
    end

    push!(meta_channel, data)
end

