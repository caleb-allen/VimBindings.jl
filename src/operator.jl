
function operator_fn(c :: Char) :: Symbol
    operators = Dict(
        'c' => :change,
        'y' => :yank,
        'd' => :delete
    )
    return operators[c]
end

function change(buf :: IOBuffer, motion :: Motion) #, motion_type :: MotionType)
    delete(buf, motion)
end

# also, when there is whitespace following a word,
# "dw" deletes that whitespace
# and "cw" only removes the inner word
function delete(buf :: IOBuffer, motion :: Motion) #, motion_type :: MotionType)
    yank(buf, motion)
    move(buf, motion) #, motion_type)
    @log motion.stop
    @log edit_splice!(buf, motion.start => motion.stop)
    return nothing
end

# function yank(buf :: IOBuffer, motion :: Motion) #, motion_type :: MotionType)
#     yank(buf, motion)

#     # '0' is the "yank" register
#     vim.registers['0'] = cut(buf, motion)
# end
function move(buf :: IOBuffer, motion :: Motion)#, motion_type :: MotionType)
    seek(buf, motion.stop)
end

function yank(buf :: IOBuffer, motion :: Motion) :: Union{String, Nothing}
    text = cut(buf, motion)
    reg = vim.register
    # '_' is the "black hole" register
    vim.register = '"'
    if reg == '_'
        return nothing
    else
        vim.registers[reg] = text
        return text
    end
end

function insert(buf :: IOBuffer, pos :: Integer, text)
    s = string(text)
    edit_splice!(buf, pos => pos, s)
end

function cut(buf :: IOBuffer, motion :: Motion) :: String
    mark(buf)
    seek(buf, min(motion))
    chars = [ read(buf, Char) for i in 1:length(motion) if !eof(buf) ]
    reset(buf)
    return String(chars)
end

function paste(buf :: IOBuffer, reg :: Char)
    if !(reg in vim.registers.keys)
        return
    end
    pos = position(buf)
    edit_splice!(buf, pos => pos, vim.registers[reg])
end
