# This file contains alterations to LineEdit.jl

import .Threads.@spawn
import REPL.LineEdit: TextTerminal, ModalInterface, MIState, activate, keymap, match_input, keymap_data, transition, mode, terminal, refresh_line
import REPL.Terminals: raw!, enable_bracketed_paste, disable_bracketed_paste
function LE.prompt!(term::TextTerminal, prompt::ModalInterface, s::MIState=init_state(term, prompt))
    Base.reseteof(term)
    raw!(term, true)
    enable_bracketed_paste(term)
    try
        activate(prompt, s, term, term)
        if !initialized
            init()
            refresh_line(s)
        end
        old_state = mode(s)
        while true
            kmap = keymap(s, prompt)
            fcn = match_input(kmap, s)
            kdata = keymap_data(s, prompt)
            s.current_action = :unknown # if the to-be-run action doesn't update this field,
            # :unknown will be recorded in the last_action field
            local status
            # errors in keymaps shouldn't cause the REPL to fail, so wrap in a
            # try/catch block
            try
                @debug status = fcn(s, kdata)
            catch e
                @error "Error in the keymap" exception = e, catch_backtrace()
                # try to cleanup and get `s` back to its original state before returning
                transition(s, :reset)
                transition(s, old_state)
                status = :done
            end
            status !== :ignore && (s.last_action = s.current_action)
            if status === :abort
                s.aborted = true
                return buffer(s), false, false
            elseif status === :done
                return buffer(s), true, false
            elseif status === :suspend
                if Sys.isunix()
                    return buffer(s), true, true
                end
            else
                @assert status ∈ (:ok, :ignore)
            end
        end
    finally
        raw!(term, false) && disable_bracketed_paste(term)
    end
    # unreachable
end

function LE.match_input(f::Function, s::Union{Nothing,LE.MIState}, term, cs::Vector{Char}, keymap)
    @debug("match function")
    @debug cs
    LE.update_key_repeats(s, cs)
    c = String(cs)
    fallback_fn = function (s, p)  # s::Union{Nothing,MIState}; p can be (at least) a LineEditREPL, PrefixSearchState, Nothing
        r = Base.invokelatest(f, s, p, c)
        if isa(r, Symbol)
            return r
        else
            return :ok
        end
    end
    if state.mode == normal_mode
        return function (s, p)
            local result
            try
                @debug result = strike_key(c, s)
            catch e
                @error "Error while executing vim key strike" exception = e, catch_backtrace()
                result = NoAction()
            end
            if result isa Fallback
                return fallback_fn(s, p)
            end
            if result isa FallbackAlternate
                alt_fn = get_fn(keymap, result.cs)
                r = Base.invokelatest(alt_fn, s, p, c)
                if isa(r, Symbol)
                    return r
                else
                    return :ok
                end
            end
            return :ok
        end
    end

    return fallback_fn
end

function LE.match_input(k::Nothing, s, term, cs, keymap)
    @debug("match nothing")
    @debug cs
    return (s, p) -> begin
        @debug("nothing")
        return :ok
    end
end
LE.match_input(k::KeyAlias, s::Union{Nothing,LE.MIState}, term, cs, keymap::Dict{Char}) = LE.match_input(keymap, s, IOBuffer(k.seq), Char[], keymap)

function LE.match_input(k::Dict{Char}, s::Union{Nothing,LE.MIState}, term::Union{LE.AbstractTerminal,IOBuffer}=terminal(s), cs::Vector{Char}=Char[], keymap::Dict{Char}=k)
    # if we run out of characters to match before resolving an action,
    # return an empty keymap function
    eof(term) && return (s, p) -> begin
        @debug("eof: aborting")
        :abort
    end
    c = read(term, Char)
    @debug(escape_string("Reading byte $c"))
    @debug("cs: " * escape_string(string(cs)))
    if isempty(cs) && c == '\e'
        is_escape_task = @async begin
            sleep(0.03)
            avail = bytesavailable(term)
            if avail > 0
                @debug("bytes available to read: suspected encoded sequence")
                return false
            else
                @debug("no bytes available to read: suspected Escape key")
                return true
            end
        end
        is_escape = fetch(is_escape_task)
        @debug("is escape_key?")

        if is_escape
            @debug("yes escape")
            if state.mode === normal_mode
                result = strike_key("\e\e", s)
            else
                trigger_normal_mode(s)
            end
            return (s, p) -> :ok
        else
            @debug("not escape key.")
        end
    end
    @debug(escape_string("matching input for `$c`"))
    # Ignore any `wildcard` as this is used as a
    # placeholder for the wildcard (see normalize_key("*"))
    c == LE.wildcard && return (s, p) -> begin
        @debug("ignoring wildcard character")
        :ok
    end
    push!(cs, c)
    # if state.mode == normal_mode
    #     local result
    #     try
    #         @debug result = strike_key(c, s)
    #     catch e
    #         @error "Error while executing vim key strike" exception = e, catch_backtrace()
    #         result = NoAction()
    #     end
    #     # @debug c, cs
    #     # if result isa Fallback
    #     # append!(cs, result.cs[begin:end-1])
    #     cs = result.cs
    #     x = k
    #     for char in cs
    #         if @debug haskey(x, char)
    #             x = x[char]
    #         end
    #         # @debug k[char]
    #     end
    #     # return LE.match_input(x, s, term, cs, keymap)
    #     # else
    #     if result isa NoAction
    #         return (s, p) -> :ok
    #     end
    #     # result isa Fallback || 
    #     @debug c, cs
    # end
    @debug escape_string(LE.input_string(s))
    @debug haskey(k, c)
    key = haskey(k, c) ? c : LE.wildcard
    # if we don't match on the key, look for a default action then fallback on 'nothing' to ignore
    # if we don't match on the key, look for a default action then fallback on 'nothing' to ignore
    return LE.match_input(get(k, key, nothing), s, term, cs, keymap)
end

LE.prompt_string(t::REPL.TextInterface) = "$(typeof(t))"

"""
Get the key binding function `key` from `keymap`
"""
get_fn(keymap::Dict, key::String) = get_fn(keymap, collect(key))
function get_fn(keymap::Dict, cs::Vector{Char})::Function
    map = keymap
    for c in cs
        map = map[c]
    end
    fn = map
    return fn
end

abstract type StrikeKeyResult end
# No action was appiled
struct NoAction <: StrikeKeyResult end
# REPL should run default command
struct Fallback <: StrikeKeyResult
    cs::Vector{Char}
end
# An alternate key strike to use
struct FallbackAlternate <: StrikeKeyResult
    cs::Vector{Char}
end
FallbackAlternate(s::AbstractString) = FallbackAlternate(collect(s))
struct VimAction <: StrikeKeyResult end
# e.g. invalid/incomplete vim command
# struct InvalidAction <: StrikeKeyResult end



