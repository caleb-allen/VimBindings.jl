module Motions

using REPL
using REPL.LineEdit
const LE = LineEdit
using ..TextUtils
using ..Util
using ..TextObjects

export Motion, MotionType, motions, insert_motions, gen_motion, is_stationary,
        down, up, word_next, word_big_next, word_end, word_back,
        word_big_back, word_big_end, line_end, line_begin, line_zero,
        find_c, get_safe_name, all_keys, special_keys, exclusive, inclusive

@enum MotionType begin
    linewise
    exclusive # characterwise
    inclusive # characterwise
end

struct Motion
    start :: Int64
    stop :: Int64
    motiontype :: Union{Nothing, MotionType}
end

Motion(start :: Int64, stop :: Int64) = Motion(start, stop, nothing)
Motion(buf :: IO, change :: Int64) = Motion(position(buf), position(buf) + change)
Motion(buf :: IO) = Motion(buf, 0)
Motion(tup :: Tuple{Int64, Int64}) = Motion(tup[1], tup[2], nothing)
"""
    A character motion is either inclusive or exclusive.  When inclusive, the
start and end position of the motion are included in the operation.  When
exclusive, the last character towards the end of the buffer is not included.
    Linewise motions always include the start and end position.
"""

function (m::Motion)(s :: LE.MIState)
    buf = LE.buffer(s)
    seek(buf, m.stop)
end

function (m::Motion)(buf :: IO)
    seek(buf, m.stop)
end

# Motion(to :: TextObject) = Motion(to.start, to.stop)

Base.min(motion :: Motion) = min(motion.start, motion.stop)

Base.max(motion :: Motion) =
    if motion.motiontype == inclusive
        max(motion.start, motion.stop + 1)
    else
        max(motion.start, motion.stop)
    end

is_stationary(motion :: Motion) :: Bool = motion.start == motion.stop

Base.length(motion :: Motion) = max(motion) - min(motion)

function Base.:+(motion1 :: Motion, motion2 :: Motion)
    low = Base.min(
        min(motion1),
        min(motion2)
    )
    high = Base.max(
        max(motion1),
        max(motion2)
    )
    return Motion(low, high)
end

function down(buf :: IO) :: Motion
    start = position(buf)
    npos = something(findprev(isequal(UInt8('\n')), buf.data[1:buf.size], position(buf)), 0)
    # We're interested in character count, not byte count
    offset = length(String(buf.data[(npos+1):(position(buf))]))
    npos2 = findnext(isequal(UInt8('\n')), buf.data[1:buf.size], position(buf)+1)
    if npos2 === nothing #we're in the last line
        return Motion(start, start)
    end
    # return Motion(npos, npos2)
    seek(buf, npos2)
    for _ = 1:offset
        pos = position(buf)
        if eof(buf) || read(buf, Char) == '\n'
            seek(buf, pos)
            break
        end
    end
    endd = position(buf)
    seek(buf, start)
    return Motion(start, endd)
end

function up(buf :: IO) :: Motion
    start = position(buf)
    npos = findprev(isequal(UInt8('\n')), buf.data, position(buf))
    npos === nothing && return Motion(start, start) # we're in the first line
    # We're interested in character count, not byte count
    offset = length(LE.content(buf, npos => position(buf)))
    npos2 = something(findprev(isequal(UInt8('\n')), buf.data, npos-1), 0)
    seek(buf, npos2)
    for _ = 1:offset
        pos = position(buf)
        if read(buf, Char) == '\n'
            seek(buf, pos)
            break
        end
    end
    endd = position(buf)
    seek(buf, start)
    return Motion(start, endd)
end
"""
    The motion to the next word

    1. Any non whitespace after whitespace
    2. Going from alphanumeric to punctuation
    3. Going from punctuation to alphanumeric
"""
function word_next(buf :: IO) :: Motion
    mark(buf)
    start = position(buf)

    eof(buf) && return Motion(start, start)
    last_c = read(buf, Char)
    while !eof(buf)
        c = read(buf, Char)
        if is_alphanumeric(last_c) && is_punctuation(c)
            break
        elseif is_punctuation(last_c) && is_alphanumeric(c)
            break
        elseif is_whitespace(last_c) && !is_whitespace(c)
            break
        end
        last_c = c
    end
    skip(buf, -1)
    endd = position(buf)
    reset(buf)
    return Motion(start, endd, exclusive)
end

"""
    The motion to the next big word, e.g. using the `W` command
"""
function word_big_next(buf :: IO) :: Motion
    mark(buf)
    start = position(buf)

    eof(buf) && return Motion(start, start)
    last_c = read(buf, Char)
    while !eof(buf)
        c = read(buf, Char)
        if is_whitespace(last_c) && !is_whitespace(c)
            break
        end
        last_c = c
    end
    skip(buf, -1)
    endd = position(buf)
    reset(buf)
    return Motion(start, endd, exclusive)
end


function word_end(buf :: IO) :: Motion
    start = position(buf)
    eof(buf) && return Motion(start, start)

    mark(buf)
    # move to the next character, since this command will always
    # move at least 1 (or else it is EOF)
    read(buf, Char)

    @log first_word_char = !eof(buf) && read(buf, Char)
    # find the first character of the word we will be moving to the end of
    while !eof(buf) && position(buf) != start && is_whitespace(first_word_char)
        @log first_word_char = read(buf, Char)
    end

    while !eof(buf)
        c = read(buf, Char)
        if is_punctuation(first_word_char) && !is_punctuation(c)
            LE.char_move_left(buf)
            break
        elseif is_alphanumeric(first_word_char) && !is_alphanumeric(c)
            LE.char_move_left(buf)
            break
        end
    end
    LE.char_move_left(buf)
    @log endd = position(buf)
    @log typeof(endd)
    reset(buf)
    return Motion(start, endd, inclusive)
end

function word_back(buf :: IO) :: Motion
    start = position(buf)
    position(buf) == 0 && return Motion(start, start)

    skip(buf, -1)
    last_c = peek(buf, Char)

    while position(buf) > 0
        c = peek(buf, Char)
        if is_alphanumeric(c) && is_punctuation(last_c)
            skip(buf, 1)
            break
        elseif is_punctuation(c) && is_alphanumeric(last_c)
            skip(buf, 1)
            break
        elseif is_whitespace(c) && !is_whitespace(last_c)
            skip(buf, 1)
            break
        end
        last_c = c
        LE.char_move_left(buf)
    end
    endd = position(buf)
    seek(buf, start)
    return Motion(start, endd, exclusive)
end

function word_big_back(buf :: IO) :: Motion
    start = position(buf)
    position(buf) == 0 && return Motion(start, start)

    skip(buf, -1)
    last_c = peek(buf, Char)

    while position(buf) > 0
        c = peek(buf, Char)
        if is_whitespace(c) && !is_whitespace(last_c)
            skip(buf, 1)
            break
        end
        last_c = c
        LE.char_move_left(buf)
    end
    endd = position(buf)
    seek(buf, start)
    return Motion(start, endd, exclusive)
end

function word_big_end(buf :: IO) :: Motion
    start = position(buf)
    eof(buf) && return Motion(buf)

    mark(buf)
    # move to the next character, since this command will always
    # move at least 1 (or else it is EOF)
    read(buf, Char)

    @log first_word_char = !eof(buf) && read(buf, Char)
    # find the first character of the word we will be moving to the end of
    while !eof(buf) && position(buf) != start && is_whitespace(first_word_char)
        @log first_word_char = read(buf, Char)
    end

    while !eof(buf)
        c = read(buf, Char)
        if is_whitespace(c)
            LE.char_move_left(buf)
            break
        end
    end
    LE.char_move_left(buf)
    @log endd = position(buf)
    @log typeof(endd)
    reset(buf)
    return Motion(start, endd, inclusive)
end

function line_end(buf :: IO) :: Motion
    mark(buf)
    start = position(buf)

    while !eof(buf)
        c = read(buf, Char)
        if is_linebreak(c)
            break
        end
    end
    skip(buf, -1)
    endd = position(buf)
    reset(buf)
    return Motion(start, endd, inclusive)
end

function line_begin(buf :: IO) :: Motion
    start = position(buf)
    position(buf) == 0 && return Motion(start, start)

    # skip(buf, -1)

    first_line_char = start
    while position(buf) > 0
        LE.char_move_left(buf)
        c = peek(buf, Char)
        if is_linebreak(c)
            break
        end
        if !is_whitespace(c)
            first_line_char = position(buf)
        end
    end
    if first_line_char == start
        skip(buf, 1)
        while !eof(buf)
            c = read(buf, Char)
            if !is_whitespace(c)
                skip(buf, -1)
                first_line_char = position(buf)
                break
            end
            if is_linebreak(c)
                break
            end
        end
    end

    endd = first_line_char
    seek(buf, start)
    return Motion(start, endd, exclusive)
end

"""
    The beginning of a line, including whitespace
"""
function line_zero(buf :: IO) :: Motion
    start = position(buf)
    position(buf) == 0 && return Motion(start, start)

    first_line_char = start
    while position(buf) > 0
        LE.char_move_left(buf)
        c = peek(buf, Char)
        if is_linebreak(c)
            break
        end
        first_line_char = position(buf)
    end
    endd = first_line_char
    seek(buf, start)
    return Motion(start, endd)
end

# function line_end (buf)
#     start = position(buf)
#     while !eof(buf)
#         c = read(buf, Char)
#         if newline(c)
#             break
#         end
#     end
#     endd = position(buf)
#     return Motion(start, endd)
# end

function endd(buf :: IO) :: Motion

end

function find_c(buf :: IO, query_c :: Char) :: Motion
    start = position(buf)
    endd = start

    # read one char to bump us by 1
    eof(buf) || read(buf, Char)
    while !eof(buf)
        c = read(buf, Char)
        if c == query_c
            skip(buf, -1)
            endd = position(buf)
            break
        end
    end
    return Motion(start, endd)
end

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
    'h' => (buf) -> Motion(position(buf), max(position(buf) - 1, 0), exclusive), # , exclusive
    'l' => (buf) -> Motion(position(buf), min(position(buf) + 1, buf.size), exclusive),# exclusive
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
    '0' => line_zero, # TODO how to parse this? it's a digit, not an alphabetical character.
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



LE.char_move_left(vb :: VimBuffer) = LE.char_move_left(vb.buf)
end