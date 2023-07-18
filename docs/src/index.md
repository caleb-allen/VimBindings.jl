Vim bindings for the Julia REPL.

# Introduction

VimBindings.jl is a Julia package which brings vim emulation directly to the Julia REPL. Feedback is welcome!

```@contents
Pages = ["index.md", "features.md"]
```


## Installation

```julia
julia> import Pkg
julia> Pkg.add("VimBindings")
```

## Configuration

VimBindings.jl can be loaded from `startup.jl` like so:

```julia
# in your startup file, usually ~/.julia/config/startup.jl
if isinteractive()
    @eval using VimBindings
end
```

!!! warning
    VimBindings.jl must be loaded **before** the REPL is initialized. This means that the call `@eval using VimBindings` must not be called within `atreplinit`, unlike most packages.

!!! info "Incremental compilation warnings"
    VimBindings.jl overwrites some REPL related methods in the standard library in order to add new features, causing a variety of warnings about breaking incremental compilation.
    
    Overwriting methods is not ideal (and there may be a [solution](https://github.com/caleb-allen/VimBindings.jl/issues/70) which avoids this altogether), but in the meantime this should not cause issues unless you are using other packages which also heavily modify the REPL.


## Usage

Start julia as normal. Once the REPL has loaded, you will see a pipe | cursor. This indicates that you are in insert mode, which is similar to the standard REPL experience.

Navigate to Normal mode by striking `Esc`. Normal mode is indicated with a block █ cursor. From here, you can use vim motions, text objects, operators, etc. For a full list of implemented commands, see [Features](@ref).


### Tmux users
A common practice for users of tmux is to set the `escape-time` setting of tmux to `0`, often after experiencing lag while using vim from within tmux. 

Using `escape-time` set to `0` may cause the VimBindings.jl library to sieze completely and become unresponsive. A higher value will fix this and won't cause noticeable lag. The technical reason for this can be seen in [this issue](https://github.com/caleb-allen/VimBindings.jl/issues/18#issuecomment-1381018008).

Tmux users wishing to use julia with `VimBindings.jl` should set `escape-time` to a value above `0`, for example:

```bash
# .tmux.conf
set -g escape-time 5
```

## Feedback

VimBindings.jl is early in development and likely has bugs! Issues with bug reports or general feedback is welcome.

Is your favorite vim binding missing? Add it to the ["Key bind request" thread](https://github.com/caleb-allen/VimBindings.jl/issues/15).





