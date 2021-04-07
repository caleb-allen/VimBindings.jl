module Commands
export Command, MotionCommand, OperatorCommand, LineOperatorCommand, InsertCommand

abstract type Command end

struct MotionCommand <: Command
    r1 :: Integer
    motion :: Char
end


struct OperatorCommand <: Command
    r1 :: Integer
    # one of 'y', 'd', 'c'
    operator :: Char
    r2 :: Integer
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

struct InsertCommand <: Command
    c :: Char
end
end
