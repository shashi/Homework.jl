module Homework

using Interact, Reactive
using JSON, HTTPClient
using Requires

include("encode.jl")

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
    @async push!(info, alert("info", "Verifying your answer..."))
    res = get(string(strip(config["host"], ['/']), "/hw/");
            blocking = true,
            query_params = [
                ("mode", "check"),
                ("course", config["course"]),
                ("problemset", config["problem_set"]),
                ("question", question_no),
                ("answer", JSON.json(encode(metadata, answer)))],
            headers = [("Cookie", cookie)])

    show_btn = false
    if res.http_code == 200
        result = get_response_data(res)
        if result["code"] != 0
            @async push!(info, alert("danger", "Something went wrong while verifying your code!"))
        else
            if result["data"] == 1
                @async push!(info, alert("success", "That is the correct answer!"))
                submit(config, metadata, cookie, answer, info)
            else
                @async push!(info, alert("warning", "That answer is wrong! You may try again."))
                show_btn = true
            end
        end
    else
        @async push!(info, alert("danger", "There was an unexpected error while accessing the homework server."))
    end

    b = button("Submit answer anyway...")
    lift(_ -> submit(config, question_no, cookie, answer, info), b, init=nothing)

    display(lift(msg -> display(MIME"text/html"(), msg), info))
    if show_btn
        display(b)
    end
    # return the answer itself for consistency
    answer
end

function submit(config, metadata, cookie, answer, info)
    # TODO: confirm this as the answer
    @async begin
        # The HTTP requests to evaluate answer goes here...
        # After the request, you can push the

        question_no = metadata["question"]
        res = get(string(strip(config["host"], ['/']), "/hw/");
            blocking = true,
            query_params = [
                ("mode", "submit"),
                ("course", config["course"]),
                ("problemset", config["problem_set"]),
                ("question", question_no),
                ("answer", JSON.json(encode(metadata, answer)))],
            headers = [("Cookie", cookie)])

        if res.http_code == 200
            result = get_response_data(res)
            if result["code"] != 0
                push!(info, alert("danger", "Something went wrong while submitting your answer!"))
            else
                if result["data"] == 1
                    push!(info, alert("success", "Success! Your answer is correct and has been recorded!"))
                else
                    push!(info, alert("warning", "Your answer has been recorded, however it seems to be wrong. You may try again!"))
                end
            end
        else
            push!(info, alert("danger", "There was an unexpected error while accessing the homework server."))
        end
    end
end

end # module
