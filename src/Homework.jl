module Homework

using Interact, Reactive
using JSON, HTTPClient
using Requires

# Load javascript into IJulia
display(MIME"text/html"(),
    """<script>$(readall(Pkg.dir("Homework", "src", "homework.js")))</script>""")

type Html
    html::String
end

import Base.writemime
Base.writemime(io::IO, ::MIME"text/html", x::Html) = write(io, x.html)

script(expr) =
    Html(string("<script>", expr, "</script>"))

configure(key) =
    display(script(string("Homework.config = ", JSON.json(key))))

alert(level, text) =
    "<div class='alert alert-$level'>$text</div>"

teeprint(x) =
    begin println(x); x end # A useful debugging function

get_response_data(x) =
    x.body |> takebuf_string |> JSON.parse

include("encode.jl")

function set_metadata(question, key, value)
    script("Homework.set_meta(" * JSON.json(question) * ", " * JSON.json(key) * ", " * JSON.json(value) * ")")
end

#
# Save answer in a closure for the submit button event,
# make the button and display it. return the answer as is.
#
function attempt_prompt(config_json, metadata_json, cookie, answer)

    config = JSON.parse(config_json)
    metadata = JSON.parse(metadata_json)

    info = Input(get(metadata, "info", "<div></div>"))
    metadata_channel = Input(("", ""))

    question = metadata["question"]

    lift(metadata_channel, init=script("")) do x
        k, v = x
        set_metadata(question, k, v)
    end |> display

    display(lift(msg -> set_metadata(metadata["question"], "info", msg), info, init=script("")))
    display(lift(Html, info))
    if !get(metadata, "finished", false)
        b = button("Attempt.")
        display(b)

        lift(b, init=nothing) do _
            evaluate(config, metadata, cookie, answer, info, metadata_channel)
        end
    end
    answer
end

#
# Evaluate an answer.
#

function evaluate(config, metadata, cookie, answer, info, meta)

    @assert haskey(config, "course")
    @assert haskey(config, "problem_set")
    @assert haskey(metadata, "question")

    if !haskey(config, "host")
        config["host"] = "https://juliabox.org"
    end

    question_no = metadata["question"]

    @async begin
        push!(info, alert("info", "Evaluating your answer..."))

        # The HTTP requests to evaluate answer goes here...
        # After the request, you can push the
        res = get(string(strip(config["host"], ['/']), "/hw/");
                blocking = true,
                query_params = [
                    ("mode", "submit"),
                    ("params", JSON.json([
                        "course" => config["course"],
                        "problemset" => config["problem_set"],
                        "question" => question_no,
                        "answer" => JSON.json(encode(metadata, answer))]))],
                headers = [("Cookie", cookie)])

        if res.http_code == 200
            result = get_response_data(res)
            if result["code"] != 0
                push!(info, alert("danger",
                    "Something went wrong while verifying your code!"))
            else
                report_evaluation(info, result, meta)
            end
        else
            push!(info, alert("danger",
                "There was an unexpected error while accessing the homework server."))
        end
    end

    # return the answer itself for consistency
    answer
end

function report_evaluation(info, result, meta)

    status = result["status"]
    score = result["score"]
    attempts = result["attempts"]
    max_attempts = result["max_attempts"]
    max_score = result["max_attempts"]

    if status == 1
        msg = "<span class='icon-thumps-up'></span> <b>Correct!</b> Score: $score/$max_score. Attempts: $attempt/$max_attempts."
        push!(info,
            alert("success", msg))
        push!(meta, ("finished", true))
    else
        if attempt >= max_attempts
            msg = "<span class='icon-thumps-down'></span> You have <b>exceeded the maximum number of attempts</b> allowed for this question. <br>"
            push!(meta, ("finished", true))
        else
            msg = "<span class='icon-fire'></span> <b>Wrong answer. Sorry.</b>"
        end
        msg +=  " Score: $score/$max_score. Attempts: $attempt/$max_attempts."

        push!(info,
            alert("warning", msg))
    end

end


end # module
