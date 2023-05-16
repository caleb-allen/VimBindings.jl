"""
Due to code loading issues, this module will not function correctly
if it is loaded using `atreplinit`. It must be loaded be loaded using a
command line argument when julia is started:

e.g:
  julia -i -e "using VimBindings; VimBindings.init()"
"""
module VimBindings

using REPL
using Base: AnyDict
using REPL
using REPL.LineEdit
using Match
import REPL.LineEdit: KeyAlias, edit_splice!, buffer, refresh_line
import Base: AnyDict, show_unquoted
using Sockets

const LE = LineEdit
include("util.jl")
using .Util
import .Util.@debug

include("textutils.jl")
include("command.jl")
include("textobject.jl")
include("motion.jl")
include("registers.jl")
include("operator.jl")
include("parse.jl")
include("execute.jl")
include("lineeditalt.jl")

using .Parse
using .Commands
using .Execution
using .Motions
using .TextUtils
using .Operators
using .Registers

mutable struct VimState
    registers::Dict{Char,String}
    register::Char
    mode::VimMode
end



VimState() = VimState(Dict{Char,String}(), '"', insert_mode)

global state = VimState()

global key_stack = Char[]
global initialized = false

const VTE_CURSOR_STYLE_TERMINAL_DEFAULT = "\033[0 q"
const VTE_CURSOR_STYLE_BLINK_BLOCK = "\033[1 q"
const VTE_CURSOR_STYLE_STEADY_BLOCK = "\033[2 q"
const VTE_CURSOR_STYLE_BLINK_UNDERLINE = "\033[3 q"
# TODO use underline for interim cursor for something like `rX`
const VTE_CURSOR_STYLE_STEADY_UNDERLINE = "\033[4 q"
# xterm extensions
const VTE_CURSOR_STYLE_BLINK_IBEAM = "\033[5 q"
const VTE_CURSOR_STYLE_STEADY_IBEAM = "\033[6 q"

function strike_key(c, s::LE.MIState)::StrikeKeyResult
    @debug(escape_string("Strike key: $c"))
    if c == "\e\e"
        empty!(key_stack)
        return VimAction()
    end
    append!(key_stack, c)

    # if state.mode === insert_mode
    #     cs = copy(key_stack)
    #     empty!(key_stack)
    #     return Fallback(cs)
    # end

    s_cmd = String(key_stack)
    # keys to copy from `mode`
    fallback_keys = [
        # enter
        "\r",
        # tab
        # '\t',
        # newline
        "\n",
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
        # C-c
        "\x03",
        # C-d
        "\x04",
        # C-l
        "\f"
    ]

    s_cmd in fallback_keys && begin
        @debug(escape_string("falling back for cmd `$s_cmd`"))
        cs = copy(key_stack)
        empty!(key_stack)
        return Fallback(cs)
    end
    if well_formed(s_cmd)
        @debug(escape_string("well formed command: $s_cmd"))
        empty!(key_stack)
        @debug cmd = parse_command(s_cmd)
        if cmd !== nothing
            buf = buffer(s)
            repl_action::Union{VimMode,ReplAction,Nothing} = execute(buf, cmd)
            if repl_action isa VimMode
                @debug("trigger mode...")
                trigger_mode(s, repl_action)
            elseif repl_action isa ReplAction
                global debug = s
                @debug typeof(mode(s)) # REPL.LineEdit.PrefixHistoryPrompt
                @debug typeof(s) # REPL.LineEdit.MIState
                if repl_action == history_up
                    return FallbackAlternate("\e[A")
                elseif repl_action == history_down
                    return FallbackAlternate("\e[B")
                end
            else
                LE.refresh_line(s)
            end
        end
        return VimAction()
    else
        @debug("WARN: command not well formed!")
        @debug key_stack
        # TODO if command is still a possible match, don't clear the stack.
        #  In other words, only clear the stack if the stack is definitely invalid.
        # empty!(key_stack)
        return NoAction()
    end
end

function init()
    if initialized
        return
    end
    # enable_logging()
    @debug("initializing...")
    @debug current_task()
    repl = Base.active_repl
    trigger_insert_mode(repl.mistate)
    global initialized = true
    @debug("initialized")
    return
end

function add_vim_keybinds!(mode::LE.TextInterface)
    repl = Base.active_repl
    prior_keybinds = mode.keymap_dict
    binds = AnyDict()
    for c in all_keys
        bind = (s::LE.MIState, o...) -> begin
            if state.mode == normal_mode
                @debug("normal mode. Dispatching vim key strike")
                strike_key(c, s)
            else
                @debug("insert mode")
                @debug("Defaulting to existing key binding.")
                if c in keys(prior_keybinds)
                    prior_keybinds[c](s, o...)
                else
                    @debug("No existing keybind. Writing char `$c`")
                    @debug term = LE.terminal(s)
                    write(term, c)
                end
            end
        end
        binds[c] = bind
    end

    keymap = AnyDict(
        '*' => (s::LE.MIState, o...) -> begin
            @debug("keymap fallthrough: *")
            # @debug o
        end,
        "\e\e" => (s, o...) -> begin
            @debug("key: \\e\\e")
            empty!(key_stack)
        end,
    )
    keymap = merge(keymap,
        AnyDict(binds))

    # keys to copy from `mode`
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
        # C-c
        "\x03",
        # C-d
        "\x04"
    ]

    for c in copy_keys
        (c in keys(keymap) || c in keys(mode.keymap_dict)) && continue
        keymap[c] = LE.default_keymap[c]
    end
    keymap = merge(keymap, mode.keymap_dict)

    # mode.keymap_dict = LE.keymap([keymap])
    @debug("initialized for $(LE.prompt_string(mode))")
    return

end

function edit_move_end(s::LE.MIState)
    buf = LE.buffer(s)
    @show typeof(buf)
    @loop_guard while !eof(buf)
        if linebreak(
            LE.char_move_right(buf))
            break
        end
    end
    pos = max(position(buf) - 1, # correcting adjustment
        0)
    seek(buf, pos)
    LE.refresh_line(s)
    return true
end

function edit_move_start(s::LE.MIState)
    buf = LE.buffer(s)
    @loop_guard while position(buf) > 0
        if linebreak(LE.char_move_left(buf))
            LE.char_move_right(buf)
            break
        end
    end
    pos = position(buf)
    seek(buf, pos)
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

function trigger_mode(state::LE.MIState, mode::VimMode)
    if mode == normal_mode
        trigger_normal_mode(state)
    elseif mode == insert_mode
        trigger_insert_mode(state)
    else
        @debug("Could not trigger mode ", mode)
    end
end
function trigger_insert_mode(s::LE.MIState)
    # iobuffer = LineEdit.buffer(s)
    state.mode = insert_mode
    print(stdout, VTE_CURSOR_STYLE_STEADY_IBEAM)
    @debug("trigger insert mode")
    LE.refresh_line(s)
end

function trigger_normal_mode(s::LE.MIState)
    iobuffer = LineEdit.buffer(s)
    # vim.mode = NormalMode()
    if state.mode !== normal_mode
        state.mode = normal_mode
        left(iobuffer)(iobuffer)
        print(stdout, VTE_CURSOR_STYLE_STEADY_BLOCK)
    end
    @debug("trigger normal mode")
    LE.refresh_line(s)
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

function funcdump(args...)
    socket = getsocket()
    for (i, arg) in enumerate(args)
        println(socket, "$i $(typeof(arg))")
        println(socket, string("\t", propertynames(arg)))
        println(socket)
    end
end

function enable_logging()
    Util.enable_logging()
end

function debug_info()

end

function change_mode_line()
    ansi_disablecursor = "\e[?25l"
    newtext = "vjulia>"
    ansi_enablecursor = "\e[?25h"
    ansi_clearline = "\e[2K"
    printstyled()
end


include("precompile.jl")

end
