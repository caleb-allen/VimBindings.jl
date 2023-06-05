
# Development

This file contains an unorganized set of notes about development.

# Debugging
To view logs without stdout interfering with the usage of the library, logs can be piped to a socket in a different terminal.

Listen in to the logging socket with `nc -l -p 1234`. It may be helpful to do this in a while loop so that the REPL may be repeatedly shut down and restarted (breaking the pipe).

This snippet uses fish shell, but this can be adapted to bash, zsh, etc.

```fish
while true
   echo "listening for logs"
   nc -l -p 1234
nd
```

Then, enable the pipe logging from VimBindings with `VimBindings.enable_logging()`:

```bash
# ~/.julia/dev/VimBindings
julia --project -i -e "using VimBindings; VimBindings.enable_logging()"
```

Logging can also be enabled after initialization:

```julia
julia> VimBindings.enable_logging()
Logging.ConsoleLogger(IOBuffer(data=UInt8[...], readable=false, writable=false, seekable=false, append=false, size=0, maxsize=0, ptr=1, mark=-1), Info, Logging.default_metafmt, true, 0, Dict{Any, Int64}())
```

Once logging is enabled, you should see something like this from `nc`:

```
┌ Debug: initializing...
└ @ VimBindings ~/.julia/dev/VimBindings/src/VimBindings.jl:156
┌ Debug: Task (runnable) @0x00007f13d92b7080
└ @ VimBindings ~/.julia/dev/VimBindings/src/VimBindings.jl:157
┌ Debug: trigger insert mode
└ @ VimBindings ~/.julia/dev/VimBindings/src/VimBindings.jl:226
┌ Debug: initialized
└ @ VimBindings ~/.julia/dev/VimBindings/src/VimBindings.jl:161
```

# Useful References
### Vim plugins for other editors
- https://github.com/JetBrains/ideavim
- https://github.com/neovim/neovim

### Neovim quick reference
- https://neovim.io/doc/user/quickref.html


### Vim Source code
Particularly the structs:
- https://github.com/vim/vim/blob/eb43b7f0531bd13d15580b5c262a25d6a52a0823/src/structs.h

List of all synonym commands:
- https://github.com/vim/vim/blob/759d81549c1340185f0d92524c563bb37697ea88/src/normal.c#L5365

```
{
    static char_u *(ar[8]) = {(char_u *)"dl", (char_u *)"dh",
			      (char_u *)"d$", (char_u *)"c$",
			      (char_u *)"cl", (char_u *)"cc",
			      (char_u *)"yy", (char_u *)":s\r"};
    static char_u *str = (char_u *)"xXDCsSY&";
    
x => dl
X => dh
D => d$
C => c$
s => cl
S => cc
Y => yy
& => :s\r
```

### Julia discussions
Threads related to vim bindings:

- https://github.com/JuliaLang/julia/issues/6774
- https://github.com/JuliaLang/julia/issues/9649
- https://github.com/JuliaLang/julia/issues/28598

- https://discourse.julialang.org/t/vim-mode-in-repl-command-line/9023
- https://discourse.julialang.org/t/vim-bindings-on-the-horizon/86801
