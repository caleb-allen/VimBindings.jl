"""
Due to code loading issues, this module will not function correctly
if it is loaded using `atreplinit`. It must be loaded be loaded using a
command line argument when julia is started:

e.g:
  julia -i -e "using VimBindings; VimBindings.init()"
"""
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
include("lineeditalt.jl")

using .Parse
using .Commands

@enum VimMode begin
    normal_mode
    insert_mode
    # visual
end
mutable struct VimState
    registers :: Dict{Char, String}
    register :: Char
end



VimState() = VimState(Dict{Char, String}(), '"')

const vim = VimState()

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
            buf = buffer(s)
            new_mode :: Union{VimMode, Nothing} = execute(buf, cmd)
            if new_mode !== nothing
                trigger_mode(s, new_mode)
            end

            # if refresh
            LE.refresh_line(s)
            # end
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
    log("initializing...")
    @log current_task()
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
            log("key: \\e\\e")
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
    log("initialized")
    return
end
function vim_reset()
    vim.mode = normal
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

function trigger_mode(state :: LE.MIState, mode :: VimMode)
    if mode == normal_mode
        trigger_normal_mode(state)
    elseif mode == insert_mode
        trigger_insert_mode(state)
    else
        log("Could not trigger mode ", mode)
    end
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
