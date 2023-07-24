"""
User configuration of VimBindings.jl behavior

"""
module Config
using Preferences
import ..VimBindings as VB


function __init__()
    if system_clipboard()
        println(stdout)
        @warn """System clipboard integration is enabled for VimBindings.jl.

        The commands `y`, `p` and `P` are enabled for the system clipboard.
        Note that registers are not implemented.

        The feature is not well tested;
        Feel free to share your experience with the feature on this github issue
        https://github.com/caleb-allen/VimBindings.jl/issues/7
        Remember to include information about your setup.

        Disable the feature by running
        \t VimBindings.Config.system_clipboard!(false)


        """

    end
end

# idea taken from PreferenceTools.jl
function _in_global_env(f)
    # imported at runtime, after REPL is instantiated
    @eval import Pkg
    proj = Pkg.project().path
    try
        Pkg.activate(; io=devnull)
        f()
    finally
        Pkg.activate(proj; io=devnull)
    end
end
"""
The preferences for VimBindings.jl and their values.
"""
function preferences()
    for (name, default) in prefs
        @info "$name" value=(@eval $name()) default
    end
end

# each preference name and the default value
const prefs = (
    :development_mode => false,
    :system_clipboard => false,
)
function pref_set_name(pref::Symbol)
    string(pref) * "!" |> Symbol
end
function make_pref(name::Symbol, default)
    @eval $(name)() = pref(string($name), $default)
    @eval $(Symbol(string(name) * "!"))(newval) = pref!(string($name), newval)
end

for (name, default) in prefs
    make_pref(name, default)
end

function pref!(name, value)
    _in_global_env() do
        set_preferences!(VB, name => value, force=true)
        @info "Preference set. Please restart the REPL in order for this change to take effect."
    end
end
pref(name, default = nothing) = load_preference(VB, name, default)


end

