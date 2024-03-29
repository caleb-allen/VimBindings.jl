# VimBindings.jl
VimBindings.jl is a Julia package which brings vim emulation directly to the Julia REPL.

[![](https://img.shields.io/badge/docs-blue.svg)](https://caleb-allen.github.io/VimBindings.jl/)
![latest ci](https://github.com/caleb-allen/VimBindings.jl/actions/workflows/test.yaml/badge.svg)

### Installation
```julia
julia> import Pkg

julia> Pkg.add("VimBindings")
```

Then, place the following in your julia startup file (usually `~/.julia/config/startup.jl`)

```julia
if isinteractive()
    @eval using VimBindings
end
```

### Features
- Modifies REPL to allow binding to Escape key
- vim-like bindings available in all REPL modes
- Motions (e.g. `hjkl`, word motions like `w`, `W`, `b`, `e`, etc.)
- Operators (`c` and `d`)
- Text objects (e.g. `daw`, `ciw`)
- Undo and redo implementation with vim-like semantics

A complete list of features can be found in [the documentation](https://caleb-allen.github.io/VimBindings.jl/stable/features/)

### Documentation

For more information about installation, configuration, and a full list of features, please see the [documentation](https://caleb-allen.github.io/VimBindings.jl/stable/)




### Feedback

Is there a vim command you long for that isn't implemented? Please share by using the [Key bind request thread](https://github.com/caleb-allen/VimBindings.jl/issues/15)

Issues with bug reports or general feedback is welcome.

### JuliaCon 2023 Talk

You can view the JuliaCon Talk about this package on YouTube:

[![REPL Without a Pause: Bringing VimBindings.jl to the Julia REPL | Caleb Allen | JuliaCon 2023](https://img.youtube.com/vi/XmR1f17pYFQ/0.jpg)](https://www.youtube.com/watch?v=XmR1f17pYFQ)

### In Memoriam

This project is only possible because of the incredible work of Bram Moolenaar, the creator of vim. His passing marks the loss of a world class hacker, and an amazing leader both in open source projects and in humanitarian aid with [ICCF Holland](https://iccf-holland.org/). It is with a heavy heart that we dedicate this project to his memory.