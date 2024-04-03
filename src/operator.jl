module Operators
using ..Motions
using ..Util
using ..TextUtils
using ..Registers
using ..Config

using REPL
using REPL.LineEdit
const LE = LineEdit
import InteractiveUtils.clipboard

export operator_fn, change, delete, move, yank, insert, cut, put
function operator_fn(c::Char)::Function
    operators = Dict(
        'c' => change,
        'y' => yank,
        'd' => delete
    )
    return operators[c]
end

function change(buf::IO, motion::Motion) #, motion_type :: MotionType)
    text = String(take!(copy(buf)))
    left = min(motion)
    right = min(max(motion), sizeof(text))
    @debug "change operator" buf motion text left right max(motion) length(text)
    yank(buf, motion)
    move(buf, motion) #, motion_type)
    LE.edit_splice!(buf, left => right)
end

# also, when there is whitespace following a word,
# "dw" deletes that whitespace
# and "cw" only removes the inner word
function delete(buf::IO, motion::Motion) #, motion_type :: MotionType)
    text = String(take!(copy(buf)))
    @debug "delete range:" min(motion) max(motion) length(text) textwidth(text)
    left = min(motion)
    right = max(motion)
    @debug "delete range:" left right
    move_cursor = Motion(buf)
    if motion.motiontype == linewise
        # if we're deleting a line, include the '\n' at the beginning
        if left > 1
            left -= 1
        elseif right < length(text)
            # if we're on the first line, but there is a '\n' at the end,
            # delete that '\n' as well
            right += 1
        end
        # if the line is being deleted, we want to move the cursor to the start of the current line
        # (where the line below will soon be)
        if right < length(text)
            move_cursor = line_begin(buf)
        else
            line_begin(buf)(buf)
            read_left(buf)

            move_cursor = line_begin(buf)
            # otherwise we should move the cursor to the start of the previous line
        end
    end
    @debug "delete operator" buf motion text left right move_cursor
    yank(buf, motion)
    move(buf, motion) #, motion_type)
    LE.edit_splice!(buf, left => right)

    if motion.motiontype == linewise
        move_cursor(buf)
    elseif is_line_end(buf) && !is_line_start(buf)
        let motion = snap_into_line(buf)
            motion(buf)
        end
    end

    return nothing
end

# function yank(buf :: IOBuffer, motion :: Motion) #, motion_type :: MotionType)
#     yank(buf, motion)

#     # '0' is the "yank" register
#     vim.registers['0'] = cut(buf, motion)
# end
function move(buf::IO, motion::Motion)#, motion_type :: MotionType)
    seek(buf, motion.stop)
end

function yank(buf::IO, motion::Motion)::Union{String,Nothing}
    @static if Config.system_clipboard()
        text = cut(buf, motion)
        try
            clipboard(text)
        catch e
            if e isa LoadError
                @error "Error while copying text to clipboard" text exception = (ex, catch_backtrace())
            else
                rethrow(e)
            end
        end

        @debug "yanked text" yanked = text
        return text
    else
        return ""
    end
end

insert(buf::IO, pos::Int, c::Char) = insert(buf, pos, string(c))
function insert(buf::IO, pos::Int, s::String)
    LE.edit_splice!(buf, pos => pos, s)
end

function cut(buf::IO, motion::Motion)::String
    origin = position(buf)
    seek(buf, min(motion))
    chars = [read(buf, Char) for i in 1:length(motion) if !eof(buf)]
    seek(buf, origin)
    return String(chars)
end

function put(buf::IO, reg::Char='"') # default unnamed register
    reg == '"' || @warn "Named registers are currently unsupported. Please see this issue to follow progress: https://github.com/caleb-allen/VimBindings.jl/issues/3"
    @static if Config.system_clipboard()
        text::String = try
            clipboard() |> rstrip
        catch ex
            @error "Could not read clipboard" exception = (ex, catch_backtrace())
            ""
        end
        if text === nothing
            return
        end
        pos = position(buf)
        LE.edit_splice!(buf, pos => pos, text)
    else
        println(stdout)
        @warn """Can't 'put' text; Registers are not yet implemented.

        To enable integration with the system clipboard, run the following command.

            \tVimBindings.Config.system_clipboard!(true)

        This will enable `y`, `p` and `P`.

        The system clipboard integration is not well tested;
        Please share your experience with the feature on this github issue
        https://github.com/caleb-allen/VimBindings.jl/issues/7

        Follow progress on the progress of the registers feature, see
        https://github.com/caleb-allen/VimBindings.jl/issues/3
        """
    end
end

function LE.edit_splice!(buf::VimBuffer, range::Pair{Int,Int}, text::AbstractString)
    LE.edit_splice!(buf.buf, range, text)
end

function LE.edit_splice!(buf::VimBuffer, range::Pair{Int,Int})
    LE.edit_splice!(buf.buf, range)
end
end
