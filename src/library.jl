
using DataFrames

type Html
    html::String
end

import Base.writemime
Base.writemime(io::IO, ::MIME"text/html", x::Html) = write(io, x.html)

script(expr) =
    Html(string("<script>", expr, "</script>"))

alert(level, text) =
    ["alert" => level, "msg" => text]

teeprint(x) =
    begin println(x); x end # A useful debugging function

get_response_data(x) =
    x.body |> takebuf_string |> JSON.parse

set_metadata(question, obj) =
    script("Homework.set_meta(" * JSON.json(question) * ", " * JSON.json(obj) * ")")

function make_score_dataframe(data; field="score")
    @assert field in ["score", "attempts"]
    d = Dict()
    meta = Dict()

    for q in data["questions"]
        meta[q["id"]] = string(q["max_" * field])
        for s in q["students"]
            student_scores = get(d, s["id"], Dict())
            student_scores[q["id"]] = string(s[field])
            d[s["id"]] = student_scores
        end
    end

    df = DataFrame()

    students = sort(collect(keys(d)))
    df[:Names] = ["MAX", students]
    for (q, score) in meta
        df[symbol(q)] = [meta[q], [get(get(d, s, Dict()), q, 0) for s in students]]
    end
    df
end
