module Motions

using REPL
using REPL.LineEdit
const LE = LineEdit
using ..TextUtils
using ..Util
using ..Commands

export Motion, MotionType, simple_motions, complex_motions, partial_complex_motions, insert_motions, gen_motion,
    is_stationary, down, up, word_next, word_big_next, word_end, word_back,
    word_big_back, word_big_end, line_end, line_begin, line_zero,
    find_c, find_c_back, get_safe_name, all_keys, special_keys, exclusive, inclusive, linewise, endd,
    left, right, snap_into_line

# text objects
export line

@enum MotionType begin
    linewise
    exclusive # characterwise
    inclusive # characterwise
end

struct Motion
    start::Int64
    stop::Int64
    motiontype::Union{Nothing,MotionType}
end

Motion(start::Int64, stop::Int64) = Motion(start, stop, nothing)
Motion(buf::IO, change::Int64) = Motion(position(buf), position(buf) + change)
Motion(buf::IO) = Motion(buf, 0)
Motion(tup::Tuple{Int64,Int64}) = Motion(tup[1], tup[2], nothing)
Motion(motion::Motion, motion_type::MotionType) = Motion(motion.start, motion.stop, motion_type)
"""
    A character motion is either inclusive or exclusive.  When inclusive, the
start and end position of the motion are included in the operation.  When
exclusive, the last character towards the end of the buffer is not included.
    Linewise motions always include the start and end position.
"""

function (m::Motion)(s::LE.MIState)
    buf = LE.buffer(s)
    seek(buf, m.stop)
end

function (m::Motion)(buf::IO)
    seek(buf, m.stop)
end

# Motion(to :: TextObject) = Motion(to.start, to.stop)

function Base.min(motion::Motion)
    return if motion.motiontype == inclusive && motion.stop < motion.start
        min(motion.start, motion.stop - 1)
    else
        min(motion.start, motion.stop)
    end
end
Base.max(motion::Motion) =
    if motion.motiontype == inclusive && motion.stop >= motion.start
        max(motion.start, motion.stop + 1)
    else
        max(motion.start, motion.stop)
    end

"""
The end position of the motion, adjusted for inclusive/exclusive behavior
"""
endd(motion::Motion)::Int =
    if motion.motiontype == inclusive
        if motion.stop <= motion.start
            motion.stop - 1
        else
            motion.stop + 1
        end
    else
        motion.stop
    end

is_stationary(motion::Motion)::Bool = motion.start == motion.stop

Base.length(motion::Motion) = max(motion) - min(motion)

function Base.:+(motion1::Motion, motion2::Motion)
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

function right(buf::IO)::Motion
    start = position(buf)
    @loop_guard while !eof(buf)
        c = read(buf, Char)
        eof(buf) && break
        pos = position(buf)
        nextc = read(buf, Char)
        seek(buf, pos)
        (textwidth(nextc) != 0 || nextc == '\n') && break
    end
    endd = position(buf)

    seek(buf, start)
    return Motion(start, endd, exclusive)
end

function left(buf::IO)::Motion
    start = position(buf)
    @loop_guard while position(buf) > 0 && !is_line_start(buf)
        seek(buf, position(buf) - 1)
        c = peek(buf)
        (((c & 0x80) == 0) || ((c & 0xc0) == 0xc0)) && break
    end
    pos = position(buf)
    # c = read(buf, Char)
    seek(buf, pos)
    endd = position(buf)
    seek(buf, start)
    return Motion(start, endd, exclusive)
end

function down(buf::IO)::Motion
    start = position(buf)
    npos = something(findprev(isequal(UInt8('\n')), buf.data[1:buf.size], position(buf)), 0)
    # We're interested in character count, not byte count
    offset = length(String(buf.data[(npos+1):(position(buf))]))
    npos2 = findnext(isequal(UInt8('\n')), buf.data[1:buf.size], position(buf) + 1)
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

function up(buf::IO)::Motion
    start = position(buf)
    npos = findprev(isequal(UInt8('\n')), buf.data, position(buf))
    npos === nothing && return Motion(start, start) # we're in the first line
    # We're interested in character count, not byte count
    offset = length(LE.content(buf, npos => position(buf)))
    npos2 = something(findprev(isequal(UInt8('\n')), buf.data, npos - 1), 0)
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
function word_next(buf::IO)::Motion
    origin = position(buf)
    stop = origin
    if is_word_start(buf)
        read_right(buf)
        stop = position(buf)
    end
    @loop_guard while !eof(buf) && !is_word_start(buf)
        read_right(buf)
        stop = position(buf)
    end
    seek(buf, origin)
    return Motion(origin, stop, exclusive)
end

"""
    The motion to the next big word, e.g. using the `W` command
"""
function word_big_next(buf::IO)::Motion
    origin = position(buf)
    stop = origin
    if is_object_start(buf)
        read_right(buf)
    end
    @loop_guard while !eof(buf) && !is_object_start(buf)
        read_right(buf)
        stop = position(buf)
    end
    seek(buf, origin)
    return Motion(origin, stop, exclusive)
end


function word_end(buf::IO)::Motion
    origin = position(buf)
    stop = origin
    # find the next word
    read_right(buf)
    if is_word_end(buf)
        stop = position(buf)
        read_right(buf)
    end
    @loop_guard while !eof(buf) && !is_word_end(buf)
        stop = position(buf)
        read_right(buf)
    end
    seek(buf, origin)
    return Motion(origin, stop, inclusive)
end

function word_back(buf::IO)::Motion
    origin = position(buf)
    stop = origin

    read_left(buf)
    stop = position(buf)
    @loop_guard while position(buf) > 0 && !is_word_start(buf)
        read_left(buf)
        stop = position(buf)
    end
    seek(buf, origin)
    return Motion(origin, stop, exclusive)
end

function word_big_back(buf::IO)::Motion
    origin = position(buf)
    stop = origin

    read_left(buf)
    stop = position(buf)
    @loop_guard while position(buf) > 0 && !is_object_start(buf)
        read_left(buf)
        stop = position(buf)
    end
    seek(buf, origin)
    return Motion(origin, stop, exclusive)
end

function word_big_end(buf::IO)::Motion
    origin = position(buf)
    stop = origin
    read_right(buf)
    # find the next word
    @loop_guard while !eof(buf) && !is_in_object(buf)
        read_right(buf)
    end
    @loop_guard while !eof(buf) && is_in_object(buf)
        stop = position(buf)
        read_right(buf)
    end
    seek(buf, origin)
    return Motion(origin, stop, inclusive)
end

function line_end(buf::IO)::Motion
    origin = position(buf)
    stop = position(buf)
    if is_line_end(buf)

    end
    @loop_guard while !is_line_end(buf)
        stop = position(buf)
        LE.char_move_right(buf)
    end
    seek(buf, origin)
    # if origin == stop
    #     return Motion(origin, stop + 1, inclusive)
    # end
    return Motion(origin, stop, inclusive)
end

function line_begin(buf::IO)::Motion
    origin = position(buf)
    @loop_guard while !is_line_start(buf)
        LE.char_move_left(buf)
    end

    # search for the first object character
    @loop_guard while !is_line_end(buf) && !is_object_start(buf)
        LE.char_move_right(buf)
    end

    stop = position(buf)
    seek(buf, origin)
    return Motion(origin, stop, exclusive)
end

"""
    The beginning of a line, including whitespace
"""
function line_zero(buf::IO)::Motion
    start = position(buf)
    position(buf) == 0 && return Motion(start, start)

    first_line_char = start
    @loop_guard while position(buf) > 0
        LE.char_move_left(buf)
        c = peek(buf, Char)
        if is_newline(c)
            break
        end
        first_line_char = position(buf)
    end
    endd = first_line_char
    seek(buf, start)
    return Motion(start, endd)
end

"""
Ensure the cursor is within the current line. In other words,
move left if that will put us on text that is within the line.
"""
snap_into_line(buf::IO)::Motion =
    if is_line_end(buf) && !is_line_start(buf)
        left(buf)
    else
        Motion(buf)
    end

function endd(buf::IO)::Motion

end

function find_c(buf::IO, query_c::Char)::Motion
    start = position(buf)
    endd = start

    # read one char to bump us by 1
    eof(buf) || read(buf, Char)
    @loop_guard while !eof(buf)
        c = read(buf, Char)
        if c == query_c
            skip(buf, -1)
            endd = position(buf)
            break
        end
    end
    seek(buf, start)
    return Motion(start, endd)
end

function find_c_back(buf::IO, query_c::Char)::Motion
    start = position(buf)
    position(buf) == 0 && return Motion(start, start)

    skip(buf, -1)
    # last_c = peek(buf, Char)

    @loop_guard while position(buf) >= 0
        c = peek(buf, Char)
        if c == query_c
            skip(buf, 1)
            break
        end
        # last_c = c
        LE.char_move_left(buf)
    end
    endd = position(buf)
    seek(buf, start)
    return Motion(start, endd)
end

function find_c(buf::IO, query_c::Int)
    @assert 0 <= query_c <= 9
    return find_c(buf, '0' + query_c)
end
function find_c_back(buf::IO, query_c::Int)
    @assert 0 <= query_c <= 9
    return find_c_back(buf, '0' + query_c)
end

const insert_motions = Dict{Char,Any}(
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
const simple_motions = Dict{Char,Function}(
    'h' => left,
    'l' => right,
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
    #=
    '{' => nothing,
    '}' => nothing,
    '(' => nothing,
    ')' => nothing,
    'G' => nothing,
    'H' => nothing,
    'L' => nothing
    =#
)

const complex_motions = Dict{Regex,Any}(
    r"f(.)" => (buf, char::Union{Char,Int}) -> begin
        m = find_c(buf, char)
        Motion(m, inclusive)
    end,
    r"F(.)" => (buf, char::Union{Char,Int}) -> begin
        m = find_c_back(buf, char)
        return Motion(m.start, m.stop - 1, exclusive)
    end,
    r"t(.)" => (buf, char::Union{Char,Int}) -> begin
        m = find_c(buf, char)
        adjusted_stop = max(m.start, m.stop - 1)
        return Motion(m.start, adjusted_stop, inclusive)
    end,
    r"T(.)" => (buf, char::Union{Char,Int}) -> begin
        m = find_c_back(buf, char)
        return Motion(m, exclusive)
    end,
    # r"g(.)" => (buf, char :: Union{Char, Int}) -> begin
    #     m = find_c(buf, char)
    #     Motion(m, inclusive)
    # end,
)
const partial_complex_motions = (
    r"f(.)?",
    r"F(.)?",
    r"t(.)?",
    r"T(.)?"
)

"""
    Generate a Motion object for the given `name`
"""
function gen_motion(buf, cmd::SimpleMotionCommand)::Motion
    fn_name = get_safe_name(cmd.name)
    fn = if cmd.name in keys(simple_motions)
        simple_motions[cmd.name]
    else
        @debug("$(cmd.name) has no mapped function")
        (buf) -> Motion(buf)
    end
    # call the command's function to generate the motion object
    motion = fn(buf)
    @debug "generated motion for SimpleMotionCommand" cmd motion
    return motion
end


function gen_motion(buf, cmd::TextObjectCommand)::Motion
    m = match(r"^([ai])(.)$", cmd.name)
    selection = if m[1] == "i"
        inner
    elseif m[1] == "a"
        a
    end
    text_object_fn = if m[2] == "w"
        word
    elseif m[2] == "W"
        WORD
    end
    if selection === nothing || text_object_fn === nothing
        error("Could not create a text object with \"$(cmd.name)\"")
    end
    motion = selection(buf, text_object_fn)
    @debug "generated motion for TextObjectCommand" cmd motion
    return motion
end

"""
Generate motion for the given `name` which is either a complex motion (e.g. "fX") or a TextObject
"""
function gen_motion(buf, cmd::CompositeMotionCommand)::Motion
    local fn = nothing
    for m in keys(complex_motions)
        reg_match = match(m, cmd.name)
        if reg_match !== nothing
            fn = complex_motions[m]
            break
        end
    end
    motion = fn(buf, cmd.captures...)
    @debug "generating motion for CompositeMotionCommand" cmd motion
    return motion
end


const special_keys = Dict(
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

const all_keys = Char[collect(keys(special_keys))
    collect('a':'z')
    collect('A':'Z')
    collect('0':'9')]

"""
    Get the function-safe name for the character c
"""
function get_safe_name(c::Char)::Symbol
    get(special_keys, c, string(c)) |> Symbol
end

"""
    Get the function-safe name for the string s, which must be
a 1 character string
"""
function get_safe_name(s::AbstractString)::Symbol
    if length(s) != 1
        error("length of given name is $(length(s)). Length must be 1")
    end
    return get_safe_name(s[1])
end




#################
# Text Objects
#################

"""
For the "inner" commands: If the cursor was on the object, the operator applies to 
the object. If the cursor was on white space, the operator applies to the white 
space.

Only works with words right now.
"""
function inner(buf, selection_fun)::Motion
    origin = position(buf)
    if eof(buf)
        if origin == 0
            return Motion(origin, origin)
        else
            skip(buf, -1)
        end
    end
    c = peek(buf, Char)
    if is_whitespace(c)
        return space(buf)
    else
        return selection_fun(buf)
    end
end

"""
  For non-block objects: For the "a" commands: The operator applies to the object
   and the white space after the object. If there is no white space after the object
    or when the cursor was in the white space before the object, the white space before
    the object is included.
"""
function a(buf, selection_fun)::Motion
    origin = position(buf)
    if eof(buf)
        if origin == 0
            return Motion(origin, origin)
        else
            skip(buf, -1)
        end
    end
    c = peek(buf, Char)
    if is_whitespace(c)
        return space(buf)
    else
        return selection_fun(buf)
    end
end

"""
    A word consists of a sequence of letters, digits and underscores, or a
sequence of other non-blank characters, separated with white space (spaces,
tabs, <EOL>).  This can be changed with the 'iskeyword' option.  An empty line
is also considered to be a word.
"""
function word(buf::IO)::Motion
    origin = position(buf)
    start = if is_word_start(buf)
        Motion(buf)
    else
        word_back(buf)
    end
    eof(buf) && return start
    read_right(buf)
    @loop_guard while !eof(buf) && is_in_word(buf)
        read_right(buf)
    end
    endd = Motion(buf)
    seek(buf, origin)
    motion = start + endd
    @debug "found word textobject" start endd motion
    return motion
end

"""
A WORD consists of a sequence of non-blank characters, separated with white
space.  An empty line is also considered to be a WORD.

"""
function WORD(buf::IO)::Motion
    origin = position(buf)

    eof(buf) && return Motion(origin, origin)
    is_whitespace(peek(buf, Char)) && return Motion(origin, origin)

    local start
    @loop_guard while !is_object_start(buf)
        read_left(buf)
    end
    start = position(buf)
    seek(buf, origin)


    local endd
    @loop_guard while !is_object_end(buf)
        read_right(buf)
    end
    endd = position(buf)
    seek(buf, origin)
    return Motion(start, endd)
end

"""
    Identify the text object surrounding a space
"""
function space(buf::IO)::Motion
    # use origin rather than `mark` because
    # methods called below use their own marks
    origin = position(buf)
    local start
    eof(buf) && return Motion(origin, origin)
    !is_whitespace(peek(buf, Char)) && return Motion(origin, origin)
    @loop_guard while !is_whitespace_start(buf)
        skip(buf, -1)
    end
    start = position(buf)
    seek(buf, origin)


    local endd
    @loop_guard while !is_whitespace_end(buf)
        skip(buf, 1)
    end
    endd = position(buf)
    seek(buf, origin)
    return Motion(start, endd)
end

function line(buf::IO)::Motion
    # find the line start
    origin = position(buf)
    @loop_guard while !is_line_start(buf)
        read_left(buf)
    end
    start = position(buf)
    seek(buf, origin)
    @loop_guard while !is_line_end(buf)
        read_right(buf)
    end
    stop = position(buf)
    seek(buf, origin)
    return Motion(start, stop, inclusive)
end

end
