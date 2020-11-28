
function change(s :: LE.MIState, motion :: Motion)
    buf = LE.buffer(s)
    delete(s, motion)
    trigger_insert_mode(s)
    return true
end

# TODO deleting 'exclusive' or 'inclusive'
# e.g. "dw" deletes the whole word
# but "ce" changes until the end of the word (inclusive)
# currently the implementation only changes "up to" the
# end of the word
function delete(s :: LE.MIState, motion :: Motion)
    buf = LE.buffer(s)
    yank(buf, motion)
    move(s, motion)
    @log edit_splice!(buf, motion.start => motion.stop)
    return true
end

function yank(s :: LE.MIState, motion :: Motion)
    buf = LE.buffer(s)
    yank(buf, motion)

    # '0' is the "yank" register
    vim.registers['0'] = cut(buf, motion)
end

function move(s :: LE.MIState, motion :: Motion)
    buf = LE.buffer(s)
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
