#
# Save answer in a closure for the submit button event,
# make the button and display it. return the answer as is.
#
function attempt_prompt(config_json, metadata_json, cookie, answer)

    config = JSON.parse(config_json)
    metadata = JSON.parse(metadata_json)

    metadata_channel = Input{Any}(Dict())

    question = metadata["question"]
    lift(metadata_channel, init=script("")) do x
        set_metadata(question, x)
    end |> display

    if !get(metadata, "finished", false)
        b = button("Submit »")
        display(b)

        lift(b, init=nothing) do _
            evaluate(config, metadata, cookie, answer, metadata_channel)
        end
    end
    answer
end

#
# Evaluate an answer.
#

function evaluate(config, metadata, cookie, answer, meta)
    @assert haskey(config, "course")
    @assert haskey(config, "problemset")
    @assert haskey(metadata, "question")

    if !haskey(config, "host")
        config["host"] = "https://juliabox.org"
    end
    question_no = string(metadata["question"])

    @async begin
        push!(meta, alert("info", "Evaluating your answer..."))

        # The HTTP requests to evaluate answer goes here...
        # After the request, you can push the
        res = get(string(strip(config["host"], ['/']), "/hw/");
                blocking = true,
                query_params = [
                    ("mode", "submit"),
                    ("params", JSON.json([
                        "course" => config["course"],
                        "problemset" => config["problemset"],
                        "question" => question_no,
                        "answer" => JSON.json(encode(metadata, answer))]))],
                headers = [("Cookie", cookie)])


        if res.http_code == 200
            result = get_response_data(res)
            if result["code"] != 0
                push!(meta, alert("danger", "Something went wrong while verifying your code!"))
            else
                report_evaluation(result, metadata, meta)
            end
        else
            push!(meta, alert("danger",
                "There was an unexpected error while accessing the homework server."))
        end
    end

    # return the answer itself for consistency
    answer
end

function report_evaluation(result, metadata, meta_channel)

    data = result["data"]
    status = data["status"]
    score = data["score"]
    attempts = data["attempts"]
    data["max_attempts"] = data["max_attempts"] == 0 ? get(metadata, "max_attempts", 0) : data["max_attempts"]
    max_attempts = data["max_attempts"]
    max_score = data["max_score"]

    if status == 1
        msg = "<span class='icon-thumbs-up'></span> Your last attempt was <b>correct!"
        merge!(data,
            alert("success", msg))
        data["finished"] = true
    else
        if max_attempts != 0 && attempts >= max_attempts
            msg = "<span class='icon-thumbs-down'></span> You <b>exceeded the maximum number of attempts</b> allowed for this question."
            data["finished"] = true
        else
            msg = "<span class='icon-eraser'></span> Wrong answer. <b>Try again.</b>"
        end

        merge!(data,
            alert("warning", msg,))
    end

    push!(meta_channel, data)
end

