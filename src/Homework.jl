module Homework

using Interact, Reactive
using JSON, HTTPClient
using Requires

using IJulia.CommManager

const global_config = Dict()

const state = Dict()

include("library.jl")

function reinit()

    # Load javascript into IJulia
    display(MIME"text/html"(),
        """<script>$(readall(Pkg.dir("Homework", "src", "homework.js")))</script>""")

    # Push some metadata to the Julia side
    comm = Comm(:HomeworkData)
    display(script("IPython.notebook.kernel.comm_manager.comms[" * JSON.json(comm.id) * """].then(
        function (comm) {
            comm.send({
                cookie: document.cookie,
                host: IPython.notebook.metadata.homework.host,
                course: IPython.notebook.metadata.homework.course,
                mode: IPython.notebook.metadata.homework.mode,
                problemset: IPython.notebook.metadata.homework.problemset
            })
        }
    )"""))

    #                      |
    #                      \
    #                      |
    #                      \
    #                      |
    #                      v


    comm.on_msg = msg -> begin
        global_config["cookie"] = msg.content["data"]["cookie"]

        if haskey(msg.content["data"], "host")
            global_config["host"] = msg.content["data"]["host"]
        end

        global_config["course"] = msg.content["data"]["course"]
        global_config["problemset"] = msg.content["data"]["problemset"]

        if haskey(msg.content["data"], "mode")
            global_config["mode"] = msg.content["data"]["mode"]
        end
    end
    
    # state["refresh_dashboard"] = (b = button("Refresh")) |> signal
    # display(b)
    # (state["dashboard"] = Input(Html("Loading more..."))) |> display

end

reinit()

include("encode.jl")
include("user.jl")
include("admin.jl")

end # module
