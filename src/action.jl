

# abstract type Action end

# struct Delete <: Action end

# struct Move <: Action end

# TODO - use multiple dispatch to hold action state
# struct Change <: Action
# state :: LE.MIState,
# end


global action = :move

for a in Symbol[:delete, :move]
    @eval function ($a)()
        global action = Symbol($a)
        return true
    end
end

function change(s :: LE.MIState, motion :: Motion)
    delete(buf, motion)
    trigger_insert_mode()
    return true
end

function delete(buf :: IOBuffer, motion :: Motion)
    move(buf, motion)
    @log edit_splice!(buf, motion.start => motion.stop)
    move()
    return true
end

function move(buf :: IOBuffer, motion :: Motion)
    seek(buf, motion.stop)
end
