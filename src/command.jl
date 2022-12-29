module Commands
export Command, MotionCommand, OperatorCommand, LineOperatorCommand, InsertCommand,
        SynonymCommand, SimpleMotionCommand, CompositeMotionCommand
export key

abstract type Command end

abstract type MotionCommand <: Command end

"""
Command which is a motion made up of 1 character
"""
struct SimpleMotionCommand <: MotionCommand
    r1 :: Int
    motion :: Char
end

SimpleMotionCommand(::Nothing, motion :: Char) = SimpleMotionCommand(1, motion)

struct CompositeMotionCommand <: MotionCommand
    r1 :: Int
    motion :: String
    captures
end
    
CompositeMotionCommand(::Nothing, motion :: String, captures :: Vararg) = CompositeMotionCommand(1, motion, captures)

MotionCommand(r1 :: Int, motion :: Char) = SimpleMotionCommand(r1, motion)
MotionCommand(r1 :: Int, motion :: String, captures :: Vararg) = CompositeMotionCommand(r1, motion, captures)

function MotionCommand(n1 :: Union{Integer, Nothing}, m :: Union{String, Char}) :: MotionCommand
    r1 = if n1 === nothing 1 else n1 end
    return MotionCommand(r1, m)
end

"""
Command which operates on a selection of text, for example yank `y`, cut `c`, or delete `d`
"""
struct OperatorCommand <: Command
    r1 :: Int
    # one of 'y', 'd', 'c'
    operator :: Char
    r2 :: Int
    # e.g. 'iw' or 'w'
    # char = motion, string = textobject
    action :: Union{Char, String}
end

# OperatorCommand
function OperatorCommand(n1 :: Union{Integer, Nothing},
                 operator :: Char,
                 n2 :: Union{Integer, Nothing},
                 motion :: Union{Char, Nothing},
                 textobject :: Union{String, Nothing}) :: OperatorCommand
    r1 = if n1 === nothing 1 else n1 end
    r2 = if n2 === nothing 1 else n2 end
    if motion === nothing && textobject === nothing
        error("Both `motion` and `textobject` are empty.")
    end
    action = if motion !== nothing motion else textobject end
    return OperatorCommand(r1,
                           operator,
                           r2,
                           action)
end

"""
    Command which operates on lines by repeating a motion
e.g. "5dd"
"""
struct LineOperatorCommand <: Command
    r1 :: Int
    operator :: Char
end

function LineOperatorCommand(n1 :: Union{Integer, Nothing},
                 operator1 :: Char,
                 operator2 :: Char) :: LineOperatorCommand
    r1 = if n1 === nothing 1 else n1 end
    if operator1 != operator2
        error("operator1 is not equal to operator2: $operator1 != $operator2")
    end
    return LineOperatorCommand(r1, operator1)
end

"""
Command which after parsing is a synonym of another command
"""
struct SynonymCommand <: Command
    r1 :: Int
    operator :: Char 
end

function SynonymCommand(n1 :: Union{Integer, Nothing}, m :: Char) :: SynonymCommand
    r1 = if n1 === nothing 1 else n1 end
    return SynonymCommand(r1, m)
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
