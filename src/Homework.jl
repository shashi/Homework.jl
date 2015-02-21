module Homework

using Interact, Reactive
using JSON, HTTPClient
using Requires

include("encode.jl")
include("library.jl")
include("user.jl")
include("admin.jl")

end # module
