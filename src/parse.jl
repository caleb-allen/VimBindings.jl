module Parse
import DataStructures: OrderedDict
using ..Commands
using ..Motions
using ..Util
import ..Util.log

export well_formed, matched_rule, parse_command, synonym, partial_well_formed

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
motion=begin
    implemented_keys = join([k for k in keys(simple_motions) if k != '0'])
    "[$implemented_keys]"
end
# motions with multiple keystrokes e.g. 'fx'
function complex_motion() :: String
    local motion_regexes = keys(complex_motions) |> collect
    patterns = map(motion_regexes) do regex
        regex.pattern
    end
    join(patterns, "|")
end
textobject="$repeat[ai][wWsp]"
operator="[ydc]"
rules = OrderedDict(
    # insert commands
    r"^(?<c>[aAiIoO])$" => InsertCommand,
    # Special case: `0` is a motion command:
    "^0\$" |> Regex => (() -> MotionCommand(nothing, '0')),
    # synonym commands
    "^(?<n1>$repeat)(?<c>[xXCS])\$" |> Regex => SynonymCommand,
    "^(?<n1>$repeat)($motion)\$" |> Regex => SimpleMotionCommand,
    "^(?<n1>$repeat)((?|$(complex_motion())))\$" |> Regex => CompositeMotionCommand,
    "^(?<n1>$repeat)(?<op>$operator)(?<n2>$repeat)(?|($textobject)|($motion))\$" |> Regex => OperatorCommand,
    "^(?<n1>$repeat)(?<op>$operator)(?<n2>$repeat)((?|$(complex_motion())))\$" |> Regex => OperatorCommand,
    "^(?<n1>$repeat)(?<op>$operator)(\\k<op>)\$" |> Regex => LineOperatorCommand,
    "^(?<n1>$repeat)r(.)\$" |> Regex => ReplaceCommand
)

# same as above, but valid for partially completed string commands. This is to determine when the key stack should be cleared.
partial_rules() = OrderedDict(
    # insert commands
    r"^(?<c>[aAiIoO])" => InsertCommand,
    # Special case: `0` is a motion command:
    "^0\$" |> Regex => (() -> MotionCommand(nothing, '0')),
    # synonym commands
    "^(?<n1>$repeat)(?<c>[xXCS])" |> Regex => SynonymCommand,
    "^(?<n1>$repeat)($motion)" |> Regex => SimpleMotionCommand,
    "^(?<n1>$repeat)((?|$(complex_motion())))" |> Regex => CompositeMotionCommand,
    "^(?<n1>$repeat)(?<op>$operator)(?<n2>$repeat)(?|($textobject)|($motion))" |> Regex => OperatorCommand,
    "^(?<n1>$repeat)(?<op>$operator)(?<n2>$repeat)((?|$(complex_motion())))" |> Regex => OperatorCommand,
    "^(?<n1>$repeat)(?<op>$operator)(\\k<op>)" |> Regex => LineOperatorCommand,
    "^(?<n1>$repeat)r(.)" |> Regex => ReplaceCommand
)

"""
Determines whether the given string is accepted as a vim command.
"""
function well_formed(cmd :: String) :: Bool
    for rule in keys(rules)
        if occursin(rule, cmd)
            return true
        end
    end
    return false
end

function partial_well_formed(cmd :: String) :: Bool
    for rule in keys(partial_rules())
        @show match(rule, cmd)
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
function parse_value(item :: Union{Nothing, AbstractString}) :: Union{Integer, Char, AbstractString, Nothing}
    if item === nothing || isempty(item)
        return nothing
    end
    if match(r"^\d+$", item) !== nothing
        return parse(Int, item)
    end
    if length(item) == 1
        return item[1]
    end
    return item
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


# function parse(cmd :: String)
#     rule = matched_rule(cmd)
#     @assert rule !== nothing
#     m = match(rule, cmd)
#     return m
# end

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
