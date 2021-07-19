# Intro

VimBindings is a Julia package which brings vim keybindings and modal editing to the Julia REPL.

VimBindings is early in development and is not ready for real-world use.

I believe Julia makes a great candidate for a vim implementation, and for interactive applications in general, and this is an exercise for me in software development in Julia. 

# Features
- [x] Normal mode
- [x] Basic navigation (`h`, `j`, `k`, `l`,)
- [x] Binding escape key from Julia REPL (see #8)
- [x] Basic editing (e.g. `dw`, `cw`, `x`)
- [ ] Less basic editing (e.g. `diw`, `cfx`)
- [ ] History integration
- [ ] Visual mode
- [x] Registers
- [ ] Undo/Redo
- [ ] Macros

# Installation

```julia
] add https://github.com/caleb-allen/VimBindings.jl

```

# Usage

The VimBindings package must be loaded before the REPL so that it can override some key-mapping functionality to correctly bind the 'escape' key. You can do this in your startup config:
```julia
# .julia/config/startup.jl
atreplinit() do repl
    @eval using VimBindings
end
```
After starting the REPL, call `VimBindings.init()`

```julia
julia> VimBindings.init()
julia[i]> # You now have vim bindings!
```

VimBindings begins in `insert` mode, and the Julia REPL can be used in its original, familiar fasion.

Switch to `normal` mode by pressing Esc, where you can navigate with `h`, `j`, `k`, `l`, etc.
```julia
julia[i]> println("Hello world!") # user presses Esc
julia[n]> println("Hello world!") # normal mode!
```
![gif of usage](https://raw.githubusercontent.com/caleb-allen/VimBindings.jl/master/vimbindings.gif)
