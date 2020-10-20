module VimBindings

using REPL
using REPL.LineEdit
import REPL.LineEdit.KeyAlias
import Base: AnyDict, show_unquoted
using Sockets
include("textobject.jl")

const LE = LineEdit

function init()
    repl = Base.active_repl
    global juliamode = repl.interface.modes[1]
    juliamode.prompt = "julia[i]> "
    juliamode.keymap_dict['`'] = trigger_normal_mode
    #= juliamode.keymap_dict['\e'] = trigger_normal_mode =#

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

    keymap = AnyDict(
        # backspace
        '\b' => (s::LE.MIState, o...)->LE.edit_move_left(s),
        'h' => (s::LE.MIState, o...)->LE.edit_move_left(s),
        'l' => (s::LE.MIState, o...)->LE.edit_move_right(s),
        'k' => (s::LE.MIState, o...)->LE.edit_move_up(s),
        'j' => (s::LE.MIState, o...)->LE.edit_move_down(s),
        'e' => (s::LE.MIState, o...)->LE.edit_move_word_right(s),
        'E' => (s::LE.MIState, o...)->edit_move_phrase_right(s),
        'b' => (s::LE.MIState, o...)->LE.edit_move_word_left(s),
        'B' => (s::LE.MIState, o...)->edit_move_phrase_left(s),
        'a' => (s::LE.MIState, o...)->begin
        LE.edit_move_right(s)
        trigger_insert_mode(s, o...)
        end,
        'A' => (s::LE.MIState, o...)->begin
        edit_move_end(s)
        trigger_insert_mode(s, o...)
        end,
        'i' => trigger_insert_mode,
        '$' => (s::LE.MIState, o...)->edit_move_end(s),
        '^' => (s::LE.MIState, o...)->edit_move_start(s),
        'x' => (s::LE.MIState, o...)->LE.edit_delete(s),
    )

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
        "\e[A",
        # down arrow
        "\e[B",
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
                    # on_enter = juliamode.on_enter,
                    )
    normalmode.on_done = juliamode.on_done
    normalmode.on_enter = juliamode.on_enter

    push!(repl.interface.modes, normalmode)
    return
end


function edit_move_end(s::LE.MIState)
    buf = LE.buffer(s)
    while !eof(buf)
        if is_line_break_char(
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
        if is_line_break_char(LE.char_move_left(buf))
            LE.char_move_right(buf)
            break
        end
    end
    pos = position(buf)
    seek(buf,pos)
    LE.refresh_line(s)
    return true
end


is_line_break_char(c::Char) = c in """\n"""
is_whitespace_char(c::Char) = c in """ \t\n"""
is_non_word_char(c::Char) = LE.is_non_word_char(c)
is_word_char(c::Char) = !LE.is_non_word_char(c)
is_punct_char(c::Char) = LE.is_non_word_char(c) && !is_non_phrase_char(c)

function edit_move_phrase_right(s::LE.MIState)
    buf = LE.buffer(s)
    if !eof(buf)
        LE.char_move_word_right(buf, is_whitespace_char)
        return LE.refresh_line(s)
    end
    return true
end

function edit_move_phrase_left(s::LE.MIState)
    buf = LE.buffer(s)
    if position(buf) > 0
        LE.char_move_word_left(buf, is_whitespace_char)
        return LE.refresh_line(s)
    end
    return true
end
macro log(exs...)
    blk = Expr(:block)
    for ex in exs
        push!(blk.args, :(println(getsocket(), $(sprint(show_unquoted,ex)*" = "),
                                  repr(begin value=$(esc(ex)) end))))
    end
    isempty(exs) || push!(blk.args, :value)
    return blk
end

function trigger_insert_mode(state::LineEdit.MIState, repl::Any, char::AbstractString)
    iobuffer = LineEdit.buffer(state)
    LineEdit.transition(state, juliamode) do
        prompt_state = LineEdit.state(state, juliamode)
        prompt_state.input_buffer = copy(iobuffer)
    end
end

function trigger_normal_mode(state::LineEdit.MIState, repl::LineEditREPL, char::AbstractString)
    iobuffer = LineEdit.buffer(state)
    LineEdit.transition(state, normalmode) do
        prompt_state = LineEdit.state(state, normalmode)
        prompt_state.input_buffer = copy(iobuffer)
    end
end


function key_press(state::REPL.LineEdit.MIState, repl::LineEditREPL, char::String)
end


function getsocket()
    if !isdefined(VimBindings, :socket)
        global socket = connect(1234)
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
