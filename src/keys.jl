#=
-----------
Normal Mode
-----------
=#
function i(buf :: IOBuffer) :: Motion
    start = position(buf)
    # leave it in the same spot
    return Motion(start, start)
end

function i_big(buf :: IOBuffer) :: Motion
    return line_begin(buf)
end

function a(buf :: IOBuffer) :: Motion
    if !eof(buf)
        return Motion(position(buf), position(buf) + 1)
    else
        return Motion(position(buf), position(buf))
    end
end

function a_big(buf :: IOBuffer) :: Motion
    motion = line_end(buf)
    return if !eof(buf)
        return Motion(motion.start, motion.stop + 1)
    else
        return motion
    end
end

# function x(mode :: NormalMode, s::LE.MIState)
#     buf = LE.buffer(s)
#     motion = Motion(position(buf), position(buf) + 1)
#     execute(MotionMode{Delete}(), s, motion)
#     LE.refresh_line(s)
#     return true
# end

# function p(mode::NormalMode, s::LE.MIState)
#     buf = LE.buffer(s)
#     paste(buf, vim.register)
#     LE.refresh_line(s)
# end



function double_quote(mode::NormalMode, s::LE.MIState) :: Action
    @log vim.mode = SelectRegister()
end

#=
function f(mode::MotionMode{T} where T, s::LE.MIState) :: Action
    @log t = eltype(mode)
    @log vim.mode = FindChar{t}()
end

function d(mode::MotionMode{Delete}, s) :: Action
    buf = buffer(s)
    motion = Motion(line(buf))
    execute(mode, s, motion, linewise)
    refresh_line(s)
    vim_reset()
    return true
end

function y(mode::MotionMode{Yank}, s) :: Action
    buf = buffer(s)
    motion = Motion(line(buf))
    execute(mode, s, motion, linewise)
    vim_reset()
    return true
end


# function execute(::AbstractSelectMode{Yank},
#                  s :: LE.MIState,
#                  motion::Motion,
#                  motion_type::MotionType)
#     yank(s, motion, motion_type)
# end

=#

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
