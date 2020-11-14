# Intro

VimBindings is a Julia package which brings vim keybindings and modal editing to the Julia REPL.

VimBindings is early in development and is likely not ready for real-world use.

As heavy user of vim myself my goal is to make this implementation as fully featured as possible, to make it "feel" like the real vim and not just some rebound hotkeys thrown on, at least as far as that is possible. I'd like to avoid the experience I've had with so many vim implementations (in IDEs, mostly) which implement the basic features, but don't go far enough or whose own hotkeys or designs clash with vim's.

This is also an exercise in Julia for me, and I believe Julia makes a great candidate for a vim implementation. Not only is the REPL code modular and user accessible, (with existing modes like `shell>`, `help?>`, and `pkg>`), Julia's metaprogramming capabilities + type system make for succinct and highly expressive code, perfect for a DSL-like system such as vim. Additionally, the REPL paradigm is essentially a line editor, and so unlike an IDE the potential for clashing designs is low.

# Features
- [x] Normal mode
- [x] Basic navigation (`h`, `j`, `k`, `l`,)
- [x] Basic editing (e.g. `dw`, `cw`, `x`)
- [ ] Less basic editing (e.g. `diw`, `cfx`)
- [ ] History integration
- [ ] Visual mode
- [ ] Registers
- [ ] Undo/Redo
- [ ] Macros

# Installation

```julia
] add https://github.com/caleb-allen/VimBindings.jl

julia> using VimBindings

julia> VimBindings.init()

julia[i]> 
```

# Usage
VimBindings begins in `insert` mode, and the Julia REPL can be used in its original, familiar fasion.

Switch to `normal` mode by using the backtic, where you can navigate with `h`, `j`, `k`, `l`, etc.
```julia
julia[i]> println("Hello world!") # user presses backtic "`"
julia[n]> println("Hello world!") # normal mode!
```
![gif of usage](https://raw.githubusercontent.com/caleb-allen/VimBindings.jl/master/vimbindings.gif)]
