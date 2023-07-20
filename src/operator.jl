module Operators
using ..Motions
using ..Util
using ..TextUtils
using ..Registers

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
    right = min(max(motion), length(text))
    @debug "delete operator" buf motion text left right
    yank(buf, motion)
    move(buf, motion) #, motion_type)
    LE.edit_splice!(buf, left => right)

    # delete(buf, motion)
end

# also, when there is whitespace following a word,
# "dw" deletes that whitespace
# and "cw" only removes the inner word
function delete(buf::IO, motion::Motion) #, motion_type :: MotionType)
    text = String(take!(copy(buf)))
    left = min(motion)
    right = min(max(motion), length(text))
    @debug "delete operator" buf motion text left right
    yank(buf, motion)
    move(buf, motion) #, motion_type)
    LE.edit_splice!(buf, left => right)
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
    text = cut(buf, motion)
    clipboard(text)
    @debug "yanked text" yanked = text
    # put!(nothing, text)
    return text
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
end

function LE.edit_splice!(buf::VimBuffer, range::Pair{Int,Int}, text::AbstractString)
    LE.edit_splice!(buf.buf, range, text)
end

function LE.edit_splice!(buf::VimBuffer, range::Pair{Int,Int})
    LE.edit_splice!(buf.buf, range)
end
end