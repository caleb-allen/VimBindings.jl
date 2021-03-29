


#=
function change(s :: LE.MIState, motion :: Motion, motion_type :: MotionType)
    buf = LE.buffer(s)
    delete(s, motion)
    trigger_insert_mode(s)
    return true
end

# also, when there is whitespace following a word,
# "dw" deletes that whitespace
# and "cw" only removes the inner word
function delete(s :: LE.MIState, motion :: Motion, motion_type :: MotionType)
    buf = LE.buffer(s)
    yank(buf, motion)
    move(s, motion, motion_type)
    @log stop
    @log edit_splice!(buf, motion.start => stop)
    return true
end

function yank(s :: LE.MIState, motion :: Motion, motion_type :: MotionType)
    buf = LE.buffer(s)
    yank(buf, motion)

    # '0' is the "yank" register
    vim.registers['0'] = cut(buf, motion)
end
=#
function move(s :: LE.MIState, motion :: Motion)#, motion_type :: MotionType)
    buf = LE.buffer(s)
    seek(buf, motion.stop)
end

#=

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

function cut(buf :: IOBuffer, motion :: Motion) :: String
    mark(buf)
    seek(buf, min(motion))
    chars = [ read(buf, Char) for i in 1:length(motion) ]
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
=#
