module Commands
export Command, MotionCommand, OperatorCommand, LineOperatorCommand, InsertCommand,
        SynonymCommand, SimpleMotionCommand, CompositeMotionCommand, TextObjectCommand, ReplaceCommand
export key

abstract type Command end

abstract type MotionCommand <: Command end

"""
Command which is a motion made up of 1 character
"""
struct SimpleMotionCommand <: MotionCommand
    r1 :: Int
    name :: Char
end

SimpleMotionCommand(::Nothing, name :: Char) = SimpleMotionCommand(1, name)

function Base.:(==)(cmd1 :: Command, cmd2 :: Command)
    typeof(cmd1) == typeof(cmd2) || return false
    for name in propertynames(cmd1)
        if getproperty(cmd1, name) != getproperty(cmd2, name)
            return false
        end
    end
    return true
end

struct CompositeMotionCommand <: MotionCommand
    r1 :: Int
    name :: AbstractString
    captures :: Tuple
end
    
CompositeMotionCommand(::Nothing, name :: AbstractString, captures :: Tuple) = CompositeMotionCommand(1, name, captures)
CompositeMotionCommand(::Nothing, name :: AbstractString, captures :: Vararg) = CompositeMotionCommand(1, name, captures)

# Base.:(==)(cmd1 :: CompositeMotionCommand, cmd2 :: CompositeMotionCommand) =
#     cmd1.r1 == cmd2.r1 &&
#         cmd1.name == cmd2.name &&
#         cmd1.captures == cmd2.captures

MotionCommand(r1 :: Int, motion :: Char) = SimpleMotionCommand(r1, motion)
MotionCommand(r1 :: Int, motion :: AbstractString, captures :: Tuple) = CompositeMotionCommand(r1, motion, captures)

function MotionCommand(n1 :: Union{Integer, Nothing}, m :: Union{AbstractString, Char}) :: MotionCommand
    r1 = if n1 === nothing 1 else n1 end
    return MotionCommand(r1, m)
end

struct TextObjectCommand <: Command
    r1 :: Int
    name :: AbstractString
end

"""
Command which operates on a selection of text, for example yank `y`, cut `c`, or delete `d`
"""
struct OperatorCommand <: Command
    r1 :: Int
    # one of 'y', 'd', 'c'
    operator :: Char

    # either a motion command or a tuple with (count, text object)
    action :: Union{MotionCommand, TextObjectCommand}
end

# char action = motion
function OperatorCommand(n1 :: Union{Integer, Nothing},
                 operator :: Char,
                 n2 :: Union{Integer, Nothing},
                 action :: Char) :: OperatorCommand
    r1 = if n1 === nothing 1 else n1 end
    r2 = if n2 === nothing 1 else n2 end
    motion_command = MotionCommand(r2, action) 
    return OperatorCommand(r1,
                           operator,
                           motion_command)
end
# string action + captures = complex motion
function OperatorCommand(n1 :: Union{Integer, Nothing},
                 operator :: Char,
                 n2 :: Union{Integer, Nothing},
                 action :: AbstractString,
                 captures :: Vararg) :: OperatorCommand
    r1 = if n1 === nothing 1 else n1 end
    r2 = if n2 === nothing 1 else n2 end
    motion_command = MotionCommand(r2, action, captures)
    return OperatorCommand(r1,
                           operator,
                           motion_command)
end

# string action + no captures = text object
function OperatorCommand(n1 :: Union{Integer, Nothing},
                 operator :: Char,
                 n2 :: Union{Integer, Nothing},
                 action :: AbstractString) :: OperatorCommand
    r1 = if n1 === nothing 1 else n1 end
    r2 = if n2 === nothing 1 else n2 end
    text_object_command = TextObjectCommand(r2, action)
    return OperatorCommand(r1,
                           operator,
                           text_object_command)
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

struct ReplaceCommand <: Command
    r1 :: Int
    replacement :: Char
end

function ReplaceCommand(r1 :: Nothing, replacement :: Char)
    return ReplaceCommand(1, replacement)
end

function ReplaceCommand(r1, replacement :: Int)
    return ReplaceCommand(r1, string(replacement)[1])
end



function key(cmd :: Command) :: Char
    error("method `key` not implemented for type $(typeof(cmd))")
end

key(cmd :: MotionCommand) = cmd.name
key(cmd :: OperatorCommand) = cmd.operator
key(cmd :: LineOperatorCommand) = cmd.operator
key(cmd :: InsertCommand) = cmd.c

end
