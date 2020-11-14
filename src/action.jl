
function change(s :: LE.MIState, motion :: Motion)
    buf = LE.buffer(s)
    delete(s, motion)
    trigger_insert_mode(s)
    return true
end

function delete(s :: LE.MIState, motion :: Motion)
    buf = LE.buffer(s)
    move(s, motion)
    @log edit_splice!(buf, motion.start => motion.stop)
    return true
end

function move(s :: LE.MIState, motion :: Motion)
    buf = LE.buffer(s)
    seek(buf, motion.stop)
end
