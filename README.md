# VimBindings.jl
VimBindings.jl is a Julia package which brings vim emulation directly to the Julia REPL.

[![](https://img.shields.io/badge/docs-stable-blue.svg)](https://caleb-allen.github.io/VimBindings.jl/dev)
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

A complete list of features can be found in [the documentation](https://caleb-allen.github.io/VimBindings.jl/dev/features/)

### Documentation

For more information about installation, configuration, and features please see the [documentation](https://caleb-allen.github.io/VimBindings.jl/)

### Feedback

Is there a vim command you long for that isn't implemented? Please share by using the [Key bind request thread](https://github.com/caleb-allen/VimBindings.jl/issues/15)

Issues with bug reports or general feedback is welcome.
