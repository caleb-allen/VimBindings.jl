"""
User configuration of VimBindings.jl behavior

"""
module Config
using Preferences, UUIDs
# package ID
const VB_UUID = UUID("51b3953f-5e5d-4a6b-bd62-c64b6fa1518a")

function __init__()
    if system_clipboard()
        println(stdout)
        @warn """System clipboard integration is enabled.

        The feature is not well tested;
        Feel free to share your experience with the feature on this github issue
        https://github.com/caleb-allen/VimBindings.jl/issues/7
        Remember to include information about your setup.

        Disable the feature by running
        \t VimBindings.Config.system_clipboard!(false)


        """

    end
end

"""
The preferences for VimBindings.jl and their values.
"""
function preferences()
    map(prefs) do p
        (:preference => p[1],
            :value => @eval $(p[1])(),
            :default => p[2])
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
    @set_preferences!(name => value)
    @info "Preference set. Please restart the REPL in order for this change to take effect."
end
pref(name, default = nothing) = @load_preference(name, default)

end
