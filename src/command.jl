module Commands
export Command, MotionCommand, OperatorCommand, LineOperatorCommand, InsertCommand,
    SynonymCommand, SimpleMotionCommand, CompositeMotionCommand, TextObjectCommand, ReplaceCommand,
    ZeroCommand, HistoryCommand, ParseValue, command_constructor
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
    name :: String
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
    name :: String
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

struct ZeroCommand <: Command end
ZeroCommand(args...) = ZeroCommand()

struct HistoryCommand <: Command
    r1::Int
    c::Char
end
function HistoryCommand(n1::Union{Int, Nothing}, c::Char)
    r1 = isnothing(n1) ? 1 : n1
    HistoryCommand(r1, c)
end
function HistoryCommand(n1::Union{Int,Nothing}, c1::Char, c2::Char)
    @debug "Parsed HistoryCommand" n1 c1 c2
    # `^R` is parsed as two characters instead of 1
    r1 = isnothing(n1) ? 1 : n1
    
    c = if c1 * c2 == "^R"
        '\x12'
    else
        error("Invalid characters for HistoryCommand: `" * c1 * c2 *
            "`. Expecting `^R`.")
    end
    HistoryCommand(r1, c)
end

function key(cmd::Command)::Char
    error("method `key` not implemented for type $(typeof(cmd))")
end

key(cmd::MotionCommand) = cmd.name
key(cmd::OperatorCommand) = cmd.operator
key(cmd::LineOperatorCommand) = cmd.operator
key(cmd::InsertCommand) = cmd.c
key(cmd::HistoryCommand) = cmd.c

Base.@kwdef struct ParseValue
    type::Symbol
    i::Int=1
    c::Char=' '
    s::String=""
end
ParseValue(::Nothing) = ParseValue(type=:nothing)
ParseValue(i::Int) = ParseValue(type=:int, i=i)
ParseValue(c::Char) = ParseValue(type=:char, c=c)
ParseValue(s::AbstractString) = ParseValue(type=:string, s=s)

"""
This function unpacks the parsed values into a `Command` object.

For example, the code:
```
ReplaceCommand(1, 'c')
```
is equivalent to the code:
```
command_constructor(ReplaceCommand, ParseValue(1), ParseValue('c'))
```
The reason to use this second approach is better type stability.
(Though, a refactor with a single type-stable command struct would be better.)
"""
function command_constructor(::Type{C}, parse_values::ParseValue...) where {C<:Command}
    return command_constructor((x...) -> C(x...), parse_values...)::C
end
function command_constructor(f::F, parse_values::ParseValue...) where {F<:Function}
    if parse_values[1].type == :nothing
        return command_constructor((x...) -> f(nothing, x...), parse_values[2:end]...)
    elseif parse_values[1].type == :int
        return command_constructor((x...) -> f(parse_values[1].i, x...), parse_values[2:end]...)
    elseif parse_values[1].type == :char
        return command_constructor((x...) -> f(parse_values[1].c, x...), parse_values[2:end]...)
    elseif parse_values[1].type == :string
        return command_constructor((x...) -> f(parse_values[1].s, x...), parse_values[2:end]...)
    else
        error("unknown type $(parse_values[1].type)")
    end
end
# Finally, we call it:
command_constructor(f::F) where {F<:Function} = f()::Command


end
