# Intro

VimBindings is an experimental Julia package which brings some vim keybindings to the Julia REPL.

VimBindings is early in development and is not yet recommended for daily use. For the brave, feel free to give it a try!

![latest ci](https://github.com/caleb-allen/VimBindings.jl/actions/workflows/test.yaml/badge.svg)

# Feature development for 1.0
- [x] Normal mode
- [x] Basic navigation (`h`, `j`, `k`, `l`,)
- [x] Binding escape key from Julia REPL (see https://github.com/caleb-allen/VimBindings.jl/issues/19)
- [x] Basic editing (e.g. `dw`, `cw`, `x`)
- [x] More advanced editing with text objects (e.g. `diw`)
- [x] History integration (partial)
- [ ] Full support for Unicode characters
- 
<!-- - [ ] Visual mode -->
<!-- - [ ] Registers -->
<!-- - [ ] Undo/Redo -->
<!-- - [ ] Macros -->

# Installation

```julia
] add VimBindings

```

# Running

VimBindings must be initialized when Julia is started, and **before** `startup.jl`, like so:

```bash
$ julia -i -e "using VimBindings"
julia[i]> # You now have vim bindings!
```

The VimBindings package must be loaded before the REPL to correctly bind the `Esc` key (see https://github.com/caleb-allen/VimBindings.jl/issues/8 and https://github.com/caleb-allen/VimBindings.jl/issues/19 ). 

> **Warning**
> `VimBindings` **SHOULD NOT** be loaded in `~/.julia/config/startup.jl`, unlike most packages. Loading `VimBindings` in this manner will result in buggy/unpredictable behavior, especially related to the `Escape` key, and other keys which use escape sequences.
>
> This is because the standard library is loaded before `startup.jl` is run, and as a result any code which modifies the core behavior of the REPL from within `startup.jl` will be shadowed.
> 
> `VimBindings.jl` relies on a few important alterations to the REPL code which handles key input events. If these changes are loaded after the REPL code is started (as is the case with `startup.jl`), then the REPL code operates unmodified. Thus, the current solution is to evaluate the module before any REPL code is run at all.

You can define `vjulia` as an alias with:

```bash
alias vjulia='julia -i -e "using VimBindings"'
```

in your `.{ba,z}shrc` file.


# Usage
VimBindings begins in `insert` mode, and the Julia REPL can be used in its original, familiar fasion.

Switch to `normal` mode by pressing Esc, where you can navigate with `h`, `j`, `k`, `l`, etc.
```julia
julia[i]> println("Hello world!") # user presses Esc
julia[n]> println("Hello world!") # normal mode!
```

# Gotchas
You may see warnings about method definitions being overwritten. VimBindings.jl overwrites some methods in the standard library in order to hook into REPL functionality, and you can safely ignore these warnings.

You may experience lag when you begin to use VimBindings.jl as Julia compiles functions for the first time. This lag should ease up over time. Adding some precompilation is a longer term item on the todo list.

# Feedback

VimBindings.jl is early in development and likely has bugs! Issues with bug reports or general feedback is welcome.

Is your favorite vim binding missing? Open an issue with the tag "keybind request" to let me know!
