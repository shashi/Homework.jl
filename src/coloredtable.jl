using DataFrames
import DataFrames: _names
import Compat.String

bestmime(io, x) =
    mimewritable(MIME"text/html"(), x) ? writemime(io, MIME"text/html"(), x) : write(io, string(x))

function Base.writemime(io::IO,
                        ::MIME"text/html",
                        df::DataFrame)
    n = size(df, 1)
    cnames = _names(df)
    write(io, "<table class=\"data-frame\">")
    write(io, "<tr>")
    write(io, "<th></th>")
    for column_name in cnames
        write(io, "<th>$column_name</th>")
    end
    write(io, "</tr>")
    tty_rows, tty_cols = Base.tty_size()
    for row in 1:min(n, tty_rows)
        write(io, "<tr>")
        write(io, "<th>$row</th>")
        for column_name in cnames
            cell = df[row, column_name]
            write(io, "<td>")
            bestmime(io, cell)
            write(io, "</td>")
        end
        write(io, "</tr>")
    end
    if n > 20
        write(io, "<tr>")
        write(io, "<th>&vellip;</th>")
        for column_name in cnames
            write(io, "<td>&vellip;</td>")
        end
        write(io, "</tr>")
    end
    write(io, "</table>")

end
immutable Colored
    color::String
    value
end

Base.writemime(io::IO, ::MIME"text/html", x::Colored) =
    write(io, """<span style="color: $(x.color)">$(x.value)</span>""")


color_incomplete(mx, x, flip=false) = (x < mx) $ flip ? Colored("#a35", x) : Colored("#374", x)

tryfloat(x, d=0.0) = try float(x) catch d end
function color_progress(d)
    df = DataFrame(Names = d[:Names])
    fst = true
    for (n, c) in eachcol(d)
        if fst
            fst = false
            continue           
        end
        mx = c[1]
        df[n] = [Colored("black", mx), map(x -> color_incomplete(tryfloat(mx), tryfloat(x)), c[2:end])]
    end
    df
end
