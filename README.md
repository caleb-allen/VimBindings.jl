# Intro

VimBindings is a Julia package which brings vim keybindings and modal editing to the Julia REPL.

VimBindings is early in development and is not ready for real-world use.

I believe Julia makes a great candidate for a vim implementation, and for interactive applications in general, and this is an exercise for me in software development in Julia. 

# Features
- [x] Normal mode
- [x] Basic navigation (`h`, `j`, `k`, `l`,)
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

julia> using VimBindings; VimBindings.init()

julia[i]> 
```

# Usage
VimBindings begins in `insert` mode, and the Julia REPL can be used in its original, familiar fasion.

Currently, the user must use the backtic `\`` in place of `Esc`*.

Switch to `normal` mode by using the backtic, where you can navigate with `h`, `j`, `k`, `l`, etc.
```julia
julia[i]> println("Hello world!") # user presses backtic "`"
julia[n]> println("Hello world!") # normal mode!
```
![gif of usage](https://raw.githubusercontent.com/caleb-allen/VimBindings.jl/master/vimbindings.gif)


## Note*
Correctly handling `Esc` is a goal of this project, but doing so is made complicated by the way that escape sequences from the keyboard work in general. Here is an explanation from Wikipedia:

> If the Esc key and other keys that send escape sequences are both supposed to be meaningful to an application, an ambiguity arises if a character terminal is in use. When the application receives the ASCII escape character, it is not clear whether that character is the result of the user pressing the Esc key or whether it is the initial character of an escape sequence (e.g., resulting from an arrow key press). The traditional method of resolving the ambiguity is to observe whether or not another character quickly follows the escape character. If not, it is assumed not to be part of an escape sequence. This heuristic can fail under some circumstances, especially without fast modern communication speeds. 
https://en.wikipedia.org/wiki/Escape_sequence#Keyboard

The feature is achievable, but requires a deeper refactor of Julia's REPL code than I've been able to tackle.

See https://github.com/caleb-allen/VimBindings.jl/issues/8 and  https://github.com/JuliaLang/julia/issues/28598
