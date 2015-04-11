
encode(metadata, x) = x

encode(metadata, x::Dict) =
    [(encode(metadata, k), encode(metadata, v)) for (k, v) in x] |> sort

encode(metadata, x::Union(AbstractArray, Tuple)) =
    map(y -> encode(metadata, y), x)

function encode(metadata, x::Real)
    precision = get(metadata, "precision", 3)
    round(x, precision)
end

@require SymPy begin
    Homework.encode(metadata, x::SymPy.Sym) = "sym-" * string(x)
end

