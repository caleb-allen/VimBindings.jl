#=
-----------
Normal Mode
-----------

function i(mode :: NormalMode, s::LE.MIState) :: Action
    trigger_insert_mode(s)
end

function a(mode :: NormalMode, s::LE.MIState) :: Action
    buf = LE.buffer(s)
    motion = Motion(position(buf), position(buf) + 1)
    execute(mode, s, motion)
    trigger_insert_mode(s)
    return true
end

function x(mode :: NormalMode, s::LE.MIState) :: Action
    buf = LE.buffer(s)
    motion = Motion(position(buf), position(buf) + 1)
    execute(MotionMode{Delete}(), s, motion)
    LE.refresh_line(s)
    return true
end

function p(mode::NormalMode, s::LE.MIState) :: Action
    buf = LE.buffer(s)
    paste(buf, vim.register)
    LE.refresh_line(s)
end

function d(mode::NormalMode, s::LE.MIState) :: Action
    @log vim.mode = MotionMode{Delete}()
end

function c(mode::NormalMode, s::LE.MIState) :: Action
    @log vim.mode = MotionMode{Change}()
end

function y(mode::NormalMode, s::LE.MIState) :: Action
    @log vim.mode = MotionMode{Yank}()
end


function double_quote(mode::NormalMode, s::LE.MIState) :: Action
    @log vim.mode = SelectRegister()
end


macro motion(k, fn, motion_type)
    return quote
        function $(esc(k))(buf::IOBuffer) :: Motion
            motion = $fn(buf)
            return motion
        end
    end
end

@motion(h, (buf) -> Motion(position(buf), position(buf) - 1), exclusive)
@motion(l, (buf) -> Motion(position(buf), position(buf) + 1), exclusive)
@motion(w, word, exclusive)
@motion(e, word_end, inclusive)
@motion(b, word_back, exclusive)
@motion(caret, (buf -> Motion(position(buf), 0)), exclusive)
@motion(dollar, line_end, inclusive)


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
function get_function_name(c :: Char) :: Symbol
    get(special_keys, c, string(c)) |> Symbol
end

"""
    Get the function-safe name for the string s, which must be
a 1 character string
"""
function get_function_name(s :: AbstractString) :: Symbol
    if length(s) != 1
        error("length of given name is $(length(s)). Length must be 1")
    end
    return get_function_name(s[1])
end
=#
