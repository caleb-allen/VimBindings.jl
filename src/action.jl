
function change(s :: LE.MIState, motion :: Motion)
    delete(buf, motion)
    # trigger_insert_mode()
    return true
end

function delete(buf :: IOBuffer, motion :: Motion)
    move(buf, motion)
    @log edit_splice!(buf, motion.start => motion.stop)
    return true
end

function move(buf :: IOBuffer, motion :: Motion)
    seek(buf, motion.stop)
end
