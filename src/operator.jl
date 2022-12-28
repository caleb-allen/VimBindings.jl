module Operators
using ..Motions
using ..Util
using ..TextUtils
using ..Registers

using REPL
using REPL.LineEdit
const LE = LineEdit

export operator_fn, change, delete, move, yank, insert, cut, paste
function operator_fn(c :: Char) :: Function
    operators = Dict(
        'c' => change,
        'y' => yank,
        'd' => delete
    )
    return operators[c]
end

function change(buf :: IO, motion :: Motion) #, motion_type :: MotionType)
    delete(buf, motion)
end

# also, when there is whitespace following a word,
# "dw" deletes that whitespace
# and "cw" only removes the inner word
function delete(buf :: IO, motion :: Motion) #, motion_type :: MotionType)
    yank(buf, motion)
    move(buf, motion) #, motion_type)
    @log motion.stop
    @log LE.edit_splice!(buf, min(motion) => max(motion))
    return nothing
end

# function yank(buf :: IOBuffer, motion :: Motion) #, motion_type :: MotionType)
#     yank(buf, motion)

#     # '0' is the "yank" register
#     vim.registers['0'] = cut(buf, motion)
# end
function move(buf :: IO, motion :: Motion)#, motion_type :: MotionType)
    seek(buf, motion.stop)
end

function yank(buf :: IO, motion :: Motion) :: Union{String, Nothing}
    text = cut(buf, motion)
    
    put!(nothing, text)
    return text
end

function insert(buf :: IO, pos :: Integer, text)
    s = string(text)
    edit_splice!(buf, pos => pos, s)
end

function cut(buf :: IO, motion :: Motion) :: String
    mark(buf)
    seek(buf, min(motion))
    chars = [ read(buf, Char) for i in 1:length(motion) if !eof(buf) ]
    reset(buf)
    return String(chars)
end

function paste(buf :: IO, reg :: Char)
    text = get(reg)
    if text === nothing
        return
    end
    pos = position(buf)
    edit_splice!(buf, pos => pos, text)
end

function LE.edit_splice!(buf::VimBuffer, range :: Pair{Int, Int}, text :: AbstractString)
    LE.edit_splice!(buf.buf, range, text)
end

function LE.edit_splice!(buf::VimBuffer, range :: Pair{Int, Int})
    LE.edit_splice!(buf.buf, range)
end
end