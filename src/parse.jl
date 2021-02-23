import DataStructures: OrderedDict
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

function command(m :: RegexMatch)
    args = [ parse_value(capture) for capture in m.captures ]
    command(args...)
end

function command(n1 :: Union{Integer, Nothing},
                 motion :: Char)
end
function command(n1 :: Union{Integer, Nothing},
                 operator1 :: Char,
                 operator2 :: Char)
end

function command(n1 :: Union{Integer, Nothing},
                 operator :: Char,
                 n2 :: Union{Integer, Nothing},
                 motion :: Union{Char, Nothing},
                 textobject :: Union{String, Nothing})
    @show n1
    @show operator
    @show n2
    @show motion
    @show to
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
