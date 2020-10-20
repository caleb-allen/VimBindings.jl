# Intro

VimBindings is a Julia package which brings vim keybindings and modal editing to the Julia REPL.

VimBindings is early in development, with only sporadic features implemented based primarily on my personal needs. It is likely not ready for practical use beyond very basic navigation. As a heavy user of vim and vim bindings, though, I am hoping to become as comfortable in the Julia REPL as I am in vim itself and am adding features quickly in order to do so.

# Installation

```julia
] add https://github.com/caleb-allen/VimBindings.jl

julia> using VimBindings

julia> VimBindings.init()

julia[i]> 
```

# Usage
VimBindings begins in `insert` mode, and the Julia REPL can be used in its original, familiar fasion.

A user switches to `normal` mode by using the backtic, where they can navigate with `h`, `j`, `k`, `l`, etc.
```julia
julia[i]> println("Hello world!") # user presses backtic "`"
julia[n]> println("Hello world!") # normal mode!
```
![gif of usage](https://raw.githubusercontent.com/caleb-allen/VimBindings.jl/master/vimbindings.gif)]
