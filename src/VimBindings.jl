module VimBindings

using REPL: history_next, history_prev
using Base: AnyDict
using REPL
using REPL.LineEdit
import REPL.LineEdit: KeyAlias, edit_splice!, buffer, refresh_line
import Base: AnyDict, show_unquoted
using Sockets

const LE = LineEdit

include("util.jl")
include("textutils.jl")
include("types.jl")
include("command.jl")
include("textobject.jl")
include("execute.jl")
include("motion.jl")
include("operator.jl")
include("keys.jl")
include("parse.jl")

using .Parse
using .Commands
mutable struct VimState
    registers :: Dict{Char, String}
    register :: Char
end

VimState() = VimState(Dict{Char, String}(), '"')

const vim = VimState()
"""
dispatch_key method which takes in the char, VB.mode, s.
Same dispatch_key method for all keys.
It will do the eval of the symbol at runtime.

e.g. for normal mode (union of many modes, possible), it will dispatch_key
to the specific keybinds

but for "find" mode, there is a dispatch_key method which uses the character
to find, instead of calling that character's function.

for normal mode, take the @eval code below in order to call
the correct function at runtime.

This way, we do not need function specific bindings for every single
key, only the needed (and/or implemented) ones.
"""
function dispatch_key(c, mode, s::LE.MIState)
    log("dispatching key: ", string(c))
    fn_name = if c in keys(special_keys)
        Symbol(special_keys[c])
    elseif alphabetic(c)
        if is_lowercase(c)
            Symbol(c)
        else
            Symbol(string(lowercase(c), "_uppercase"))
        end
    else
        log("not dispatching key")
        @log c
        return
    end
    if !isdefined(VimBindings, fn_name)
        log("function $fn_name does not exist")
        return
    end
    eval(Expr(:call, fn_name, vim.mode, s))
end



# function dispatch_key(query_c :: Char, mode :: FindChar{}, s::LE.MIState)
#     buf = buffer(s)
#     motion = find_c(buf, query_c)
#     execute(mode, s, motion)
#     LE.refresh_line(s)
#     vim_reset()
# end

# function dispatch_key(c, mode :: ToChar, s::LE.MIState)
#     # TODO
# end

# function dispatch_key(c :: Char, mode :: SelectRegister, s::LE.MIState)
#     if alphanumeric(c) || c == '_'
#         @log vim.register = c
#     end
#     vim_reset()
# end

global key_stack = Char[]
global initialized = false

function strike_key(c, s::LE.MIState)
    # if(c == '`')
    #     empty!(key_stack)
    #     @log key_stack
    # else
    append!(key_stack, c)
    s_cmd = String(key_stack)
    if well_formed(s_cmd)
        log("well formed command: $s_cmd")
        empty!(key_stack)
        cmd = parse_command(s_cmd)
        if cmd !== nothing
            refresh :: Bool = execute(s, cmd)
            if refresh
                LE.refresh_line(s)
            end
        end
    else
        @log key_stack
    end
    # end
end

function init()
    if initialized
        return
    end
    global initialized = true
    repl = Base.active_repl
    global juliamode = repl.interface.modes[1]
    historymode = repl.interface.modes[4]
    prefixhistorymode = repl.interface.modes[5]
    juliamode.prompt = "julia[i]> "
    # juliamode.keymap_dict['`'] = trigger_normal_mode
    LE.add_nested_key!(juliamode.keymap_dict, "\e\e", trigger_normal_mode)
    # LE.add_nested_key!(historymode.keymap_dict, "\e\e", trigger_normal_mode)
    LE.add_nested_key!(prefixhistorymode.keymap_dict, "\e\e", trigger_normal_mode)
    # julia_mode_new_keys = AnyDict(
    #     "\e\e" =>  trigger_normal_mode,
    #     '`' =>  trigger_normal_mode
    # ) |> LE.normalize_key
    # juliamode.keymap_dict = merge(juliamode.keymap_dict, julia_mode_new_keys)
    # juliamode.keymap_dict["\e\e"] = trigger_normal_mode

    # remove normal mode if it's already added
    normalindex = 0
    for (i, m) in enumerate(repl.interface.modes)
        if hasproperty(m, :prompt) && m.prompt == "julia[n]> "
            normalindex = i
        end
    end
    if normalindex != 0
        deleteat!(repl.interface.modes, normalindex)
    end

    binds = AnyDict()
    for c in all_keys
        bind = (s::LE.MIState, o...)->begin
            strike_key(c, s)
            # dispatch_key(c, vim.mode, s)
        end
        binds[c] = bind
    end

    keymap = AnyDict(
        '*' => (s::LE.MIState, o...)->begin
            log("keymap fallthrough: *")
            # @log o
        end,
        # "\e" => (s, o...)->begin
        #     log("keymap: \\e, escape")
        # end,

        "\e\e" => (s, o...)->begin
            empty!(key_stack)
        end,
        # "\e[A" => (s::LE.MIState, o...)->begin
            # log("Up Arrow")
            # @log o
        # end,
        # backspace
        # '\b' => (s::LE.MIState, o...)->LE.edit_move_left(s),
             # '`' => (s::LE.MIState, o...)->vim_reset(),
    )
    keymap = merge(keymap,
                   AnyDict(binds))

    # keys to copy from `juliamode`
    copy_keys = [
        # enter
        '\r',
        # tab
        # '\t',
        # newline
        '\n',
        # home
        "\e[H",
        # end
        "\e[F",
        # clear
        "^L",
        # right arrow
        "\e[C",
        # left arrow
        "\e[D",
        # up arrow
        # "\e[A",
        # down arrow
        # "\e[B",
        # delete
        "\e[3~",
    ]

    for c in copy_keys
        keymap[c] = LE.default_keymap[c]
    end
    global normalmode =
        REPL.Prompt("julia[n]> ",
                    keymap_dict = LE.keymap([keymap]),
                    # on_done = REPL.respond(split, repl, juliamode),
                    on_done = (s, o...) -> begin
                        log("on_done")
                        @log s.last_action
                        @log s.current_action
                    end
                    # on_enter = juliamode.on_enter,
                    )
    normalmode.on_done = juliamode.on_done
    normalmode.on_enter = juliamode.on_enter
    normalmode.hist = juliamode.hist
    normalmode.hist.mode_mapping[:julia] = normalmode

    push!(repl.interface.modes, normalmode)
    return
end

import REPL.LineEdit: TextTerminal, ModalInterface, MIState, activate, keymap, match_input, keymap_data, transition, mode, terminal, refresh_line
import REPL.Terminals: raw!, enable_bracketed_paste, disable_bracketed_paste
function LE.prompt!(term::TextTerminal, prompt::ModalInterface, s::MIState = init_state(term, prompt))
    # println("initializing prompt from VimBindings.jl")
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

# function LE.match_input(f::Function, s::Union{Nothing,LE.MIState}, term, cs::Vector{Char}, keymap)
#     log("match function")
#     LE.update_key_repeats(s, cs)
#     c = String(cs)
#     return function (s, p)  # s::Union{Nothing,MIState}; p can be (at least) a LineEditREPL, PrefixSearchState, Nothing
#         r = Base.invokelatest(f, s, p, c)
#         if isa(r, Symbol)
#             return r
#         else
#             return :ok
#         end
#     end
# end

# function LE.match_input(k::Nothing, s, term, cs, keymap)
#     log("match nothing")
#     # @log cs
#     return (s,p) -> begin
#         log("nothing")
#         return :ok
#     end
# end
# LE.match_input(k::KeyAlias, s::Union{Nothing,LE.MIState}, term, cs, keymap::Dict{Char}) = LE.match_input(keymap, s, IOBuffer(k.seq), Char[], keymap)

function LE.match_input(k::Dict{Char}, s::Union{Nothing,LE.MIState}, term::Union{LE.AbstractTerminal,IOBuffer}=terminal(s), cs::Vector{Char}=Char[], keymap::Dict{Char} = k)
    # if we run out of characters to match before resolving an action,
    # return an empty keymap function
    eof(term) && return (s, p) -> :abort
    c = read(term, Char)
    
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
        
        if fetch(is_escape_task)
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

function vim_reset()
    vim.mode = NormalMode()
    return true
end

function edit_move_end(s::LE.MIState)
    buf = LE.buffer(s)
    @show typeof(buf)
    while !eof(buf)
        if linebreak(
            LE.char_move_right(buf))
            break
        end
    end
    pos = max(position(buf) - 1, # correcting adjustment
              0)
    seek(buf,pos)
    LE.refresh_line(s)
    return true
end

function edit_move_start(s::LE.MIState)
    buf = LE.buffer(s)
    while position(buf) > 0
        if linebreak(LE.char_move_left(buf))
            LE.char_move_right(buf)
            break
        end
    end
    pos = position(buf)
    seek(buf,pos)
    LE.refresh_line(s)
    return true
end


function edit_move_phrase_right(s::LE.MIState)
    buf = LE.buffer(s)
    if !eof(buf)
        LE.char_move_word_right(buf, whitespace)
        return LE.refresh_line(s)
    end
    return true
end

function edit_move_phrase_left(s::LE.MIState)
    buf = LE.buffer(s)
    if position(buf) > 0
        LE.char_move_word_left(buf, whitespace)
        return LE.refresh_line(s)
    end
    return true
end

function trigger_insert_mode(state::LineEdit.MIState)
    iobuffer = LineEdit.buffer(state)
    LineEdit.transition(state, juliamode) do
        prompt_state = LineEdit.state(state, juliamode)
        prompt_state.input_buffer = copy(iobuffer)
    end
end

function trigger_normal_mode(state::LineEdit.MIState, o...)
    iobuffer = LineEdit.buffer(state)
    # vim.mode = NormalMode()
    LineEdit.transition(state, normalmode) do
        prompt_state = LineEdit.state(state, normalmode)
        prompt_state.input_buffer = copy(iobuffer)
    end
end


function key_press(state::REPL.LineEdit.MIState, repl::LineEditREPL, char::String)
end


function getsocket()
    if !isdefined(VimBindings, :socket) || isa(socket, Base.DevNull)
        try
            global socket = connect(1234)
        catch e
            global socket = devnull
        end
    end
    return socket
end

function log(any::Any)
    socket = getsocket()
    println(socket, any)
end

function debug_mode(state::REPL.LineEdit.MIState, repl::LineEditREPL, char::String)
    socket = getsocket()
    # iobuffer is not displayed to the user
    iobuffer = LineEdit.buffer(state)

    # write character typed into line buffer
    #= LineEdit.edit_insert(iobuffer, char) =#
    
    # write character typed into repl
    #= LineEdit.edit_insert(state, char) =#
    #
    # move to start of iostream to read what the user
    # has typed
    seekstart(iobuffer)
    line = read(iobuffer, String)
    println(socket, "line: ", line)

    # Show what character user typed
    println(socket, "character: ", char)
end

#= juliamode.keymap_dict['9'] = debug_mode =#


function funcdump(args...)
    socket = getsocket()
    for (i, arg) in enumerate(args)
        println(socket, "$i $(typeof(arg))")
        println(socket, string("\t", propertynames(arg)))
        println(socket)
    end
end

end
