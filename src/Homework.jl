module Homework

using Interact, Reactive
using JSON

display(MIME"text/html"(),
    """<script>$(readall(Pkg.dir("Homework", "src", "homework.js")))</script>""")

macro js_str(expr)
    :(display(MIME"text/html"(), "<script>$(esc(expr))</script>"))
end

function configure(key)
    js"Homework.config = $(json(options))"
end

function evaluate(config_json, question_no, cookie, answer)
    # TODO: warn if user id / problem set is invalid,
    # do whatever and decide the answer
    # display a result (correct / not)
    # display a button that allows user to submit the answer
    config = JSON.parse(config_json)
    info = Input("<div class='alert alert-info'>Evaluating the answer...</div>")
    @async begin
        # The HTTP requests to evaluate answer goes here...
        # After the request, you can push the
        result = "<div class='alert alert-success'>Success! </div>"
        push!(info, result)
    end

    b = button("Submit last evaluated answer to question " * string(question_no))
    lift(_ -> submit(config, question_no, cookie, answer, info), b, init=nothing)

    display(lift(html, info))
    display(b)
    # return the answer itself for consistency
    answer
end

function submit(config, question_no, cookie, answer, info)
    # TODO: confirm this as the answer
    @async begin
        push!(info, "<div class='alert alert-info'>Submitting answer...</div>")
        result = "<div class='alert alert-success'>Answer submitted! 10 points!!</div>"
        push!(info, result)
    end
end

end # module
