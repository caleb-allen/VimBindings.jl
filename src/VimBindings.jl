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
using LoggingExtras, Logging
import REPL.LineEdit: KeyAlias, buffer, refresh_line
import Base: AnyDict, show_unquoted
using Sockets

const LE = LineEdit
const VTE_CURSOR_STYLE_TERMINAL_DEFAULT = "\033[0 q"
const VTE_CURSOR_STYLE_BLINK_BLOCK = "\033[1 q"
const VTE_CURSOR_STYLE_STEADY_BLOCK = "\033[2 q"
const VTE_CURSOR_STYLE_BLINK_UNDERLINE = "\033[3 q"
# TODO use underline for interim cursor for something like `rX`
const VTE_CURSOR_STYLE_STEADY_UNDERLINE = "\033[4 q"
# xterm extensions
const VTE_CURSOR_STYLE_BLINK_IBEAM = "\033[5 q"
const VTE_CURSOR_STYLE_STEADY_IBEAM = "\033[6 q"

include("config.jl")
include("util.jl")
using .Util

include("textutils.jl")
include("command.jl")
include("motion.jl")
include("registers.jl")
include("operator.jl")
include("parse.jl")
include("changes.jl")
include("execute.jl")

function __init__()
    if ccall(:jl_generating_output, Cint, ()) == 0
        include(joinpath(@__DIR__, "lineeditalt.jl"))
    end
end

using .Parse
using .Commands
using .Execution
using .Motions
using .TextUtils
using .Operators
using .Registers
using .Changes
using .Config

mutable struct VimState
    registers::Dict{Char,String}
    register::Char
    mode::VimMode
    last_edit_index::Int # where the most recent edit started
end



const global STATE = VimState(Dict{Char,String}(), '"', insert_mode, 0)
const global KEY_STACK = Char[]
const global INITIALIZED = Ref(false)




function strike_key(c, s::LE.MIState)::StrikeKeyResult
    @debug "strike key" key = escape_string(c)
    if c == "\e\e"
        empty!(KEY_STACK)
        return VimAction()
    # begin bracketed paste
    elseif c == "\e[200~"
        cs = copy(KEY_STACK)
        empty!(KEY_STACK)
        trigger_insert_mode(s)
        return Fallback(cs)
    end
    append!(KEY_STACK, c)

    s_cmd = String(KEY_STACK)
    # keys to copy from `mode`
    fallback_keys = (
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
    )

    s_cmd in fallback_keys && begin
        @debug "falling back for command" command = escape_string(s_cmd)
        cs = copy(KEY_STACK)
        empty!(KEY_STACK)
        return Fallback(cs)
    end
    if well_formed(s_cmd)
        empty!(KEY_STACK)
        cmd = parse_command(s_cmd)
        @debug "Well formed command" string = escape_string(s_cmd) command = cmd
        if cmd !== nothing
            buf = buffer(s)
            STATE.last_edit_index = position(buf)
            @debug "Last edit index" index = STATE.last_edit_index
            # record(buf)
            repl_action::Union{VimMode,ReplAction,Nothing} = execute(buf, cmd)
            if repl_action != insert_mode
                record(buf, cursor_index=STATE.last_edit_index)
            end
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
    end
    if !partial_well_formed(s_cmd)
        @debug("WARN: command not well formed!")
        @debug KEY_STACK
        empty!(KEY_STACK)
    end
    # If command is still a possible match, don't clear the stack.
    # In other words, only clear the stack if the stack is definitely invalid.
    return NoAction()
end

function init()
    if INITIALIZED[]
        return
    end
    atexit() do
        @debug "Reset cursor style"
        print(stdout, VTE_CURSOR_STYLE_STEADY_BLOCK)
    end
    # enable_logging()
    @debug current_task()
    repl = Base.active_repl
    trigger_insert_mode(repl.mistate)
    INITIALIZED.x = true
    @debug("initialized")
    return
end

LE.char_move_left(vb::VimBuffer) = LE.char_move_left(vb.buf)
LE.char_move_right(vb::VimBuffer) = LE.char_move_right(vb.buf)
"""
Make necessary modifications to vim state for a new prompt
"""
function new_prompt_line(s::LE.MIState)
    Changes.record(LE.buffer(s))
    trigger_insert_mode(s)
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
    STATE.mode = insert_mode
    print(stdout, VTE_CURSOR_STYLE_STEADY_IBEAM)
    @debug "trigger insert mode"
    LE.refresh_line(s)
end

function trigger_normal_mode(s::LE.MIState)
    iobuffer = LineEdit.buffer(s)
    record(iobuffer, cursor_index=STATE.last_edit_index)
    if STATE.mode !== normal_mode
        STATE.mode = normal_mode
        left(iobuffer)(iobuffer)
        LE.refresh_line(s)
        print(stdout, VTE_CURSOR_STYLE_STEADY_BLOCK)
    end
    @debug "trigger normal mode"
end

function reset_term_cursor()
    print(stdout, VTE_CURSOR_STYLE_TERMINAL_DEFAULT)
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

"""
Enable logging to pipe at 1234.

To read the logs, run the following:

`nc -l -p 1234`

If you're repeatedly reloading the REPL, wrapping the command in a loop is helpful:

```
while true
    echo "listening for logs"
    nc -l -p 1234
end
```

The keyword arguments correspond to enabling/disabling logs from specific files:
- `changes` for undo/redo history
- `lineeditalt` for alterations to the LineEdit.jl

"""
function enable_logging(; changes=false, lineeditalt=false, textutils=false)
    pipe = connect(1234)
    io = IOContext(pipe, :color => true)
    l = ConsoleLogger(io, Debug; right_justify=4)
    function vim_filter(log_args)
        level, message, _module, group, id, file, line, kwargs = log_args
        endswith(file, "lineeditalt.jl") && (lineeditalt || return false)
        endswith(file, "changes.jl") && (changes || return false)
        return true
    end
    early_filter(logger) =
        EarlyFilteredLogger(logger) do log
            level, _module, group, id = log
            _module == Changes && (changes || return false)
            _module == TextUtils && (textutils || return false)
            _module == LineEdit && (lineeditalt || return false)
            return true
        end
    early_log = early_filter(l)
    filtered_logger = ActiveFilteredLogger(vim_filter, early_log)
    Base.global_logger(filtered_logger)

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


include("pkgtools.jl")

end
