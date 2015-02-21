
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

function configure(key)
    display(script(string("Homework.config = ", JSON.json(key))))
end

alert(level, text) =
    ["alert" => level, "msg" => text]

teeprint(x) =
    begin println(x); x end # A useful debugging function

get_response_data(x) =
    x.body |> takebuf_string |> JSON.parse

set_metadata(question, obj) =
    script("Homework.set_meta(" * JSON.json(question) * ", " * JSON.json(obj) * ")")
