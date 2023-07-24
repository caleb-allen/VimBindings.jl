# Configuration
```@setup using
using VimBindings
```

This document describes the configuration options available to users of VimBindings.jl

To see all preferences and their settings, use `preferences()`:

```@repl using
VimBindings.Config.preferences()
```

## System Clipboard Integration

This option will enable copying and pasting with the system clipboard using `y`, `p` and `P`. It is not well tested, so it is disabled by default. Note that this does not enable "registers". To follow progress on the progress of the registers feature, see [this issue](https://github.com/caleb-allen/VimBindings.jl/issues/3)

To enable integration with the system clipboard, run the following command.
```julia
VimBindings.Config.system_clipboard!(true) # then restart your REPL session
```

Check the status of the feature with `system_clipboard()`:
```@repl using
VimBindings.Config.system_clipboard()
```

To disable the feature, run the following:

```julia
VimBindings.Config.system_clipboard!(false) # then restart your REPL session
```

!!! warning
    The system clipboard integration is not well tested; Please share your experience with the feature on [this github issue](https://github.com/caleb-allen/VimBindings.jl/issues/7)

