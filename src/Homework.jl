module Homework

using Interact, Reactive
using JSON, HTTPClient
using Requires

# Load javascript into IJulia
display(MIME"text/html"(),
    """<script>$(readall(Pkg.dir("Homework", "src", "homework.js")))</script>""")

script(expr) =
    display(MIME"text/html"(), string("<script>", expr, "</script>"))

configure(key) =
    script(string("Homework.config = ", JSON.json(key)))

alert(level, text) =
    "<div class='alert alert-$level'>$text</div>"

teeprint(x) =
    begin println(x); x end # A useful debugging function

get_response_data(x) =
    x.body |> takebuf_string |> JSON.parse

type Html
    html::String
end

import Base.writemime
Base.writemime(io::IO, ::MIME"text/html", x::Html) = x.html

include("encode.jl")


#
# Save answer in a closure for the submit button event,
# make the button and display it. return the answer as is.
#
function attempt_prompt(config_json, metadata, cookie, answer)
    b = button("Attempt")

    lift(b, init=nothing) do
        evaluate(config, question_no, cookie, answer, info)
    end |> display

    answer
end

function report_evaluation(info, result)

    status = result["status"]
    score = result["score"]
    attempts = result["attempts"]
    max_attempts = result["max_attempts"]
    max_score = result["max_attempts"]

    if status == 1
        msg = "<span class='icon-thumps-up'></span> <b>Correct!</b> Score: $score/$max_score. Attempts: $attempt/$max_attempts."
        push!(info,
            alert("success", msg))
    else
        if attempt >= max_attempts
            msg = "<span class='icon-thumps-down'></span> You have <b>exceeded the maximum number of attempts</b> allowed for this question. <br>"
        else
            msg = "<span class='icon-fire'></span> <b>Wrong answer. Sorry.</b> "
        end
        msg +=  " Score: $score/$max_score. Attempts: $attempt/$max_attempts."

        push!(info,
            alert("warning", msg))
    end

end


#
# Evaluate an answer.
#

function evaluate(config_json, metadata, cookie, answer)

    config = JSON.parse(config_json)
    if !haskey(config, "host")
        config["host"] = "https://juliabox.org"
    end

    @assert haskey(config, "course")
    @assert haskey(config, "problem_set")
    @assert haskey(metadata, "question")

    question_no = metadata["question"]

    info = Input(alert("info", "Evaluating your answer..."))

    # The HTTP requests to evaluate answer goes here...
    # After the request, you can push the
    @async begin
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
                @async push!(info, alert("danger",
                    "Something went wrong while verifying your code!"))
            else
                report_evaluation(info, result)
            end
        else
            @async push!(info, alert("danger",
                "There was an unexpected error while accessing the homework server."))
        end
    end

    display(lift(msg -> Html(msg), info))

    # return the answer itself for consistency
    answer
end

end # module
