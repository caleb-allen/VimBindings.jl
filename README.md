VimBindings.jl is an experimental Julia package which brings vim emulation directly to the Julia REPL.

The package is early in development and is not yet recommended for daily use. For the brave, feel free to give it a try!

![latest ci](https://github.com/caleb-allen/VimBindings.jl/actions/workflows/test.yaml/badge.svg)


## Installation

```julia
julia> import Pkg

julia> Pkg.add("VimBindings")

```

## Running

VimBindings must be initialized when Julia is started, and **before** `startup.jl`, like so:

```bash
$ julia -i -e "using VimBindings"
julia> # You now have vim bindings!
```

> **Warning**
> `VimBindings.jl` **MUST** be loaded in this way in order to function correctly.
>
> Unfortunately, the package cannot be instantiated from `~/.julia/config/startup.jl`. Doing so will result in buggy/unpredictable behavior.

You can define `juliavim` as an alias with:

```bash
alias juliavim='julia -i -e "using VimBindings"'
```

in your `.{ba,z}shrc` file.


## Usage
The REPL begins in Insert mode, which can be used in its familiar fashion.

VimBindings.jl emulates Normal mode, which is accessed by striking the `Escape` key.


### Insert mode
Insert mode is similar to the standard REPL experience. Insert mode is indicated with a pipe | cursor.

### Normal mode
Navigate to Normal mode by striking `Esc`. Normal mode is indicated with a block █ cursor.

<!-- #### Motion -->
<!-- The following list describes the supported navigation commands: -->

<!-- - Character motions: `h`, `j`, `k`, `l` -->
<!-- - Word motions: `w`, `W`, `e`, `E`, `b`, `B` -->
<!-- - in-line motions: `^`, `$`, `0` -->

<!-- Numbers may be prepended to motion commands, for example `5w` to move 5 words. -->

## Features
Here are a few of the features of the package, as well as goal features of the package.

- [x] Basic editing (e.g. `dw`, `cw`, `x`)
- [x] Binding the escape key from the REPL
- [x] More advanced editing with text objects (e.g. `diw`)
- [x] History integration
- [ ] Full support for Unicode characters
- [ ] System clipboard integration
- [ ] Registers
- [ ] Undo/Redo
<!-- - [ ] Visual mode -->
<!-- - [ ] Macros -->
## Issues
### Method definitions
Users may see warnings about method definitions being overwritten. VimBindings.jl overwrites some methods in the standard library in order to hook into REPL functionality. These warnings can be ignored.

### Note for tmux users experiencing freezing
A common practice for users of tmux is to set the `escape-time` setting of tmux to `0`, often after experiencing lag while using vim from within tmux.

Tmux users wishing to use julia with `VimBindings.jl` should set `escape-time` to a value above `0`, for example:

```bash
# .tmux.conf
set -g escape-time 5
```

Using `escape-time` set to `0` may cause the VimBindings.jl library to sieze completely and become unresponsive. A higher value will fix this and won't cause noticeable lag. The technical reason for this can be seen in [this issue](https://github.com/caleb-allen/VimBindings.jl/issues/18#issuecomment-1381018008).


# Feedback

VimBindings.jl is early in development and likely has bugs! Issues with bug reports or general feedback is welcome.

Is your favorite vim binding missing? Open an issue with the tag "keybind request" to let me know!


<!-- ## Addendum: Techical/historical curiosities -->

<!-- ### Why has the Julia REPL not supported vim bindings before? -->

<!-- Technically, it did! In the very (very) early days of Julia, the REPL was based on GNU Readline, a library for implementing applications with a CLI. For a load of very good reasons, the REPL [was rewritten]((https://github.com/JuliaLang/julia/pull/6270)) in Julia and lost this capability as a side effect. --> 

<!-- There are many reasons the REPL has not gained vim bindings in the intervening time, not least of which is the effort required. Implementing a vim emulation layer is not a trivial pursuit: [ideavim](https://github.com/JetBrains/ideavim/) for IntelliJ has roughly 100k lines of code; [vimium](https://github.com/philc/vimium) for chromium is in the order of 10k lines of code. -->

<!-- There are also specific technical barriers that a vim package must overcome. For instance, it is surprisingly difficult and fragile to bind the `Escape` key in a terminal application, to the point that the REPL [does not support it](https://github.com/JuliaLang/julia/issues/28598). Users of `vim` from within `tmux` have likely experienced firsthand the consequences of this bizarre historical artifact when they strike the `Escape` key and have an unexpected 500ms of lag before anything happens. This is one of the many creative solutions developers have come up with to tackle the issue. -->

<!-- Finally, the REPL is fundamentally about being a REPL: Read, Evaluate, Print, Loop. The REPL code is oriented around just that. The features required for vim emulation are --> 