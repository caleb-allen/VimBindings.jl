module Parse
import DataStructures: OrderedDict
using ..Commands

export well_formed, matched_rule, parse_command

REGS = (
    text_object = r"^.?([ai][wWsp])$",
    # complete = 
)
"""
Grammar for Vim's little language:
    1. motion
        w
        E
    2. operator [motion|textobject]
        dw
        cW
        yE
        ciw
    3. operator operator
        yy
        dd
        3dd
"""
repeat = "\\d*"
motion="[\$%^\\(\\)wWeE{}hjklGHLbB]"
# r_motion=r"([$%^\(\)wWeE{}hjklGHLbB]"
textobject="$repeat[ai][wWsp]"
operator="[ydc]"
rules = (
    "^(?<n1>$repeat)(?<motion>$motion)\$" |> Regex,
    "^(?<n1>$repeat)(?<op>$operator)(?<n2>$repeat)(?:(?<motion>$motion)|(?<to>$textobject))\$" |> Regex,
    "^(?<n1>$repeat)(?<op>$operator)(\\k<op>)\$" |> Regex
)

"""
Determines whether the given string is accepted and successfully terminates
"""
function well_formed(cmd :: String) :: Bool
    for rule in rules
        if occursin(rule, cmd)
            return true
        end
    end
    return false
end

function matched_rule(cmd :: String)
    for rule in rules
        if occursin(rule, cmd)
            return rule
        end
    end
    return nothing
end

"""
    Get the typed value of `item`
"""
function parse_value(item :: Union{Nothing, AbstractString}) :: Union{Integer, Char, String, Nothing}
    if item === nothing
        return nothing
    end
    val = Meta.parse(item)
    if typeof(val) <: Integer
        return val
    elseif typeof(val) <: Symbol
        s = String(val)
        if length(s) == 1
            return s[1]
        else
            return s
        end
    end
end


"""
    Attempt to parse a command, return nothing if `s` could not be parsed into a command
"""
function parse_command(s :: AbstractString) :: Union{Command, Nothing}
    if !well_formed(s)
        @info "command not well formed", s
        return nothing
    end
    r = matched_rule(s)
    return command(match(r, s))
end

"""
    Return a struct corresponding to a regex match's Vim command
"""
function command(m :: RegexMatch) :: Command
    args = [ parse_value(capture) for capture in m.captures ]
    return command(args...)
end

function command(n1 :: Union{Integer, Nothing},
                 motion :: Char) :: Command
    r1 = if n1 === nothing 1 else n1 end
    return MotionCommand(r1, motion)
end

function command(n1 :: Union{Integer, Nothing},
                 operator1 :: Char,
                 operator2 :: Char) :: Command
    r1 = if n1 === nothing 1 else n1 end
    if operator1 != operator2
        error("operator1 is not equal to operator2: $operator1 != $operator2")
    end
    return LineOperatorCommand(r1, operator1)
end

function command(n1 :: Union{Integer, Nothing},
                 operator :: Char,
                 n2 :: Union{Integer, Nothing},
                 motion :: Union{Char, Nothing},
                 textobject :: Union{String, Nothing}) :: Command
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



function parse(cmd :: String)
    rule = matched_rule(cmd)
    @assert rule !== nothing
    m = match(rule, cmd)
    return m
end

function Base.Dict(m :: RegexMatch)
    d = OrderedDict{Symbol, Any}()
    idx_to_capture_name = Base.PCRE.capture_names(m.regex.regex)
    if !isempty(m.captures)
        for i = 1:Base.length(m.captures)
            capture_name = get(idx_to_capture_name, i, i) |> Symbol
            d[capture_name] = m.captures[i]
        end
    end
    # Dict(Symbol(n)=>m[Symbol(n)] for n in values(Base.PCRE.capture_names(m.regex.regex)))
    return d
end



function text_object_part(cmd :: AbstractString) :: Union{String, Nothing}
    m = match(REGS.text_object, cmd)
    if m === nothing
        return nothing
    end
    return m.captures[1]
end

function verb_part(cmd :: AbstractString) :: Union{Char, Nothing}
    reg = Regex("\\d*($operator).*")
    m = match(reg, cmd)
    if m === nothing
        return nothing
    end
    return m.captures[1][1]
end
end
