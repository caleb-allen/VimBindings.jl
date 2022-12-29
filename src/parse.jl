module Parse
import DataStructures: OrderedDict
using ..Commands
using ..Motions
using ..Util
import ..Util.log

export well_formed, matched_rule, parse_command, synonym

REGS = (
    text_object = r"^.?([ai][wWsp])$",
    # complete = 
)
"""
Grammar for Vim's language:
    1. Insert commands:
        a
        A
        i
        O
    2. single-key motion
        w E
        ^
        h j k l
    3. multi-key motion
        gg
        gE
        fx
        Fx
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
repeat = "(?:[1-9]\\d*)?"
# motion="[\$%^\\(\\)wWeE{}hjklGHLbB]"
motion=begin
    implemented_keys = join([k for k in keys(simple_motions) if k != '0'])
    "[$implemented_keys]"
    # a = "[\$%^\\(\\)]"
    # a = "[
end
# motions with multiple keystrokes e.g. 'fx'
# complex_motion = "[$(join(keys(complex_motions)))]."
function complex_motion() :: String
    local motion_regexes = keys(complex_motions) |> collect
    patterns = map(motion_regexes) do regex
        regex.pattern
    end
    join(patterns, "|")
end
# r_motion=r"([$%^\(\)wWeE{}hjklGHLbB]"
textobject="$repeat[ai][wWsp]"
operator="[ydc]"
rules = OrderedDict(
    # insert commands
    r"^(?<c>[aAiIoO])$" => InsertCommand,
    # Special case: `0` is a motion command:
    "^0\$" |> Regex => (() -> MotionCommand(nothing, '0')),
    # synonym commands
    "^(?<n1>$repeat)(?<c>[xX])\$" |> Regex => SynonymCommand,
    "^(?<n1>$repeat)(?<motion>$motion)\$" |> Regex => SimpleMotionCommand,
    "^(?<n1>$repeat)((?|$(complex_motion())))\$" |> Regex => CompositeMotionCommand,
    "^(?<n1>$repeat)(?<op>$operator)(?<n2>$repeat)(?:(?<motion>$motion)|(?<to>$textobject))\$" |> Regex => OperatorCommand,
    "^(?<n1>$repeat)(?<op>$operator)(\\k<op>)\$" |> Regex => LineOperatorCommand
)

"""
Determines whether the given string is accepted and successfully terminates
"""
function well_formed(cmd :: String) :: Bool
    for rule in keys(rules)
        if occursin(rule, cmd)
            return true
        end
    end
    return false
end

function matched_rule(cmd :: String)
    for rule in keys(rules)
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
    r = matched_rule(s)
    if r === nothing
        log("command not well formed", s)
        return nothing
    end

    m = match(r, s)
    args = [ parse_value(capture) for capture in m.captures ]
    # command_dict = Dict(m)

    command_type = rules[r]
    command_type(args...)
end


"""
    Return a struct corresponding to a regex match's Vim command
"""

function synonym(command :: SynonymCommand) :: Command
    synonyms = Dict(
            'x' => "dl",
            'X' => "dh"
        )
    return parse_command("$(command.r1)$(synonyms[command.operator])")

end
    


function lookup_synonym(n :: Integer, c :: Char)
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
