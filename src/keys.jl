# using .TextObjects
insert_motions = Dict{Char, Any}(
    'i' => (buf) -> Motion(buf),
    'I' => (buf) -> line_begin(buf),
    'a' => (buf) -> begin
        return if !eof(buf)
            return Motion(position(buf), position(buf) + 1)
        else
            return Motion(buf)
        end
    end,
    'A' => (buf) -> begin
        motion = line_end(buf)
        return if !eof(buf)
            return Motion(motion.start, motion.stop + 1)
        else
            return motion
        end
    end
)

motions = Dict{Char, Any}(
    'h' => (buf) -> Motion(position(buf), position(buf) - 1), # , exclusive
    'l' => (buf) -> Motion(position(buf), position(buf) + 1),# exclusive
    'j' => down,
    'k' => up,
    'w' => word_next, # exclusive),
    'W' => word_big_next, # exclusive),
    'e' => word_end, # inclusive,
    'E' => word_big_end, # )
    'b' => word_back, # exclusive)
    'B' => word_big_back, # exclusive)
    '^' => line_begin, # exclusive)
    '$' => line_end, # inclusive)
    '0' => line_zero,
    '{' => nothing,
    '}' => nothing,
    '(' => nothing,
    ')' => nothing,
    'G' => nothing,
    'H' => nothing,
    'L' => nothing
)

"""
    Generate a Motion object for the given `name`
"""
function gen_motion(buf, name :: Char) :: Motion
    # motions = Motion[]
    fn_name = get_safe_name(name)
    fn = if name in keys(motions)
        motions[name]
    else
        log("$name has no mapped function")
        (buf) -> Motion(buf)
    end
    # call the command's function to generate the motion object
    motion = fn(buf)
    return motion
end
"""
Generate motion for the given `name` which is a TextObject
"""
function gen_motion(buf, name :: String) :: Motion
    return Motion(textobject(buf, name))
end


# function double_quote(mode::NormalMode, s::LE.MIState) :: Action
    # @log vim.mode = SelectRegister()
# end
special_keys = Dict(
    '`' => "backtic",
    '~' => "tilde",
    '!' => "bang",
    '@' => "at",
    '#' => "hash",
    '$' => "dollar",
    '%' => "percent",
    '^' => "caret",
    '&' => "ampersand",
    '*' => "asterisk",
    '(' => "open_paren",
    ')' => "close_paren",
    '-' => "dash",
    '_' => "underscore",
    '=' => "equals",
    '+' => "plus",
    '\\' => "backslash",
    '|' => "bar",
    '[' => "open_bracket",
    ']' => "close_bracket",
    '{' => "open_curly_brace",
    '}' => "close_curly_brace",
    "'"[1] => "single_quote",
    '"' => "double_quote",
    ';' => "semicolon",
    ':' => "colon",
    ',' => "comma",
    '<' => "open_angle_bracket",
    '>' => "close_angle_bracket",
    '.' => "dot",
    '/' => "slash",
    '?' => "question_mark"
)

all_keys = Char[collect(keys(special_keys));
                collect('a':'z');
                collect('A':'Z');
                collect('0':'9')]

"""
    Get the function-safe name for the character c
"""
function get_safe_name(c :: Char) :: Symbol
    get(special_keys, c, string(c)) |> Symbol
end

"""
    Get the function-safe name for the string s, which must be
a 1 character string
"""
function get_safe_name(s :: AbstractString) :: Symbol
    if length(s) != 1
        error("length of given name is $(length(s)). Length must be 1")
    end
    return get_safe_name(s[1])
end
