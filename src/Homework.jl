module Homework

using Interact, Reactive

display(MIME"text/html"(),
    """<script>$(readall(Pkg.dir("Homework", "src", "homework.js")))</script>""")

function setup_user(key)
    # TODO: Automatically do this on JuliaBox?
    # OR EdX should allow users to generate unique keys
end

function setup_problem_set(key)
end

function evaluate(question_no, answer)
    # TODO: warn if user id / problem set is invalid,
    # do whatever and decide the answer
    # display a result (correct / not)
    # display a button that allows user to submit the answer
    b = button("Submit answer to question " * string(question_no))
    lift(_ -> submit(question_no, answer), init=nothing)
    display(b)
    # return the answer itself for consistency
    answer
end

function submit(question_no, answer)
    # TODO: confirm this as the answer
end

end # module
