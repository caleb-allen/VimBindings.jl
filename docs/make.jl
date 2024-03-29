using Documenter
using VimBindings

makedocs(
    sitename = "VimBindings.jl",
    modules = [VimBindings],
    format = Documenter.HTML(
        prettyurls = get(ENV, "CI", nothing) == "true"
    ),
    pages = [
        "index.md",
        "features.md",
        "config.md"
    ]
)

# Documenter can also automatically deploy documentation to gh-pages.
# See "Hosting Documentation" and deploydocs() in the Documenter manual
# for more information.
deploydocs(
    repo = "github.com/caleb-allen/VimBindings.jl.git",
    push_preview=true
)
