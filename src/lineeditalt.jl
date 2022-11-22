# This file contains alterations to LineEdit.jl


import REPL.LineEdit: TextTerminal, ModalInterface, MIState, activate, keymap, match_input, keymap_data, transition, mode, terminal, refresh_line
import REPL.Terminals: raw!, enable_bracketed_paste, disable_bracketed_paste
function LE.prompt!(term::TextTerminal, prompt::ModalInterface, s::MIState = init_state(term, prompt))
    # log("initializing prompt from VimBindings.jl")
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
                status = fcn(s, kdata)
            catch e
                @error "Error in the keymap" exception=e,catch_backtrace()
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
    # log("match function")
    LE.update_key_repeats(s, cs)
    c = String(cs)
    return function (s, p)  # s::Union{Nothing,MIState}; p can be (at least) a LineEditREPL, PrefixSearchState, Nothing
        r = Base.invokelatest(f, s, p, c)
        if isa(r, Symbol)
            return r
        else
            return :ok
        end
    end
end

function LE.match_input(k::Nothing, s, term, cs, keymap)
    log("match nothing")
    # @log cs
    return (s,p) -> begin
        log("nothing")
        return :ok
    end
end
LE.match_input(k::KeyAlias, s::Union{Nothing,LE.MIState}, term, cs, keymap::Dict{Char}) = LE.match_input(keymap, s, IOBuffer(k.seq), Char[], keymap)

function LE.match_input(k::Dict{Char}, s::Union{Nothing,LE.MIState}, term::Union{LE.AbstractTerminal,IOBuffer}=terminal(s), cs::Vector{Char}=Char[], keymap::Dict{Char} = k)
    # if we run out of characters to match before resolving an action,
    # return an empty keymap function
    eof(term) && return (s, p) -> :abort
    c = read(term, Char)
    
    log("Reading byte ", c)
    if isempty(cs) && c == '\e'
        is_escape_task = @async begin
            sleep(0.03)
            avail = bytesavailable(term)
            if avail > 0
                log("bytes available to read: suspected encoded sequence")
                return false
            else
                log("no bytes available to read: suspected Escape key")
                return true
            end
        end
        is_escape = fetch(is_escape_task)
        log("is escape?")

        if is_escape
            @log keys(k['\e'])
            # short-circuit completion here for Escape key
            if @log haskey(k['\e'], '\e')
                return LE.match_input(k['\e']['\e'], s, term, cs, nothing)
            end
        end
    end
    # Ignore any `wildcard` as this is used as a
    # placeholder for the wildcard (see normalize_key("*"))
    c == LE.wildcard && return (s, p) -> :ok
    push!(cs, c)
    key = haskey(k, c) ? c : LE.wildcard
    # if we don't match on the key, look for a default action then fallback on 'nothing' to ignore
    return LE.match_input(get(k, key, nothing), s, term, cs, keymap)
end

