module Commands
export Command, MotionCommand, OperatorCommand, LineOperatorCommand, InsertCommand, SynonymCommand
export key

abstract type Command end

struct MotionCommand <: Command
    r1 :: Integer
    motion :: Char
end


"""
Command which operates on a selection of text, for example yank `y`, cut `c`, or delete `d`
"""
struct OperatorCommand <: Command
    r1 :: Integer
    # one of 'y', 'd', 'c'
    operator :: Char
    r2 :: Integer
    # e.g. 'iw' or 'w'
    # char = motion, string = textobject
    action :: Union{Char, String}
end

"""
    Command which operates on lines by repeating a motion
e.g. "5dd"
"""
struct LineOperatorCommand <: Command
    r1 :: Integer
    operator :: Char
end

"""
Command which after parsing is a synonym of another command
"""
struct SynonymCommand <: Command
    operator :: Char 
end
"""
Command which changes into Insert mode, possibly preceded by a motion, for example `A`.
"""
struct InsertCommand <: Command
    c :: Char
end


function key(cmd :: Command) :: Char
    error("method `key` not implemented for type $(typeof(cmd))")
end

key(cmd :: MotionCommand) = cmd.motion
key(cmd :: OperatorCommand) = cmd.operator
key(cmd :: LineOperatorCommand) = cmd.operator
key(cmd :: InsertCommand) = cmd.c

end
