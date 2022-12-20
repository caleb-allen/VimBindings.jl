using .TextUtils
struct Motion
    start :: Int64
    stop :: Int64
    motiontype
end

Motion(start :: Int64, stop :: Int64) = Motion(start, stop, nothing)
Motion(buf :: IOBuffer, change :: Int64) = Motion(position(buf), position(buf) + change)
Motion(buf :: IOBuffer) = Motion(buf, 0)
Motion(tup :: Tuple{Int64, Int64}) = Motion(tup[1], tup[2], nothing)
"""
    A character motion is either inclusive or exclusive.  When inclusive, the
start and end position of the motion are included in the operation.  When
exclusive, the last character towards the end of the buffer is not included.
    Linewise motions always include the start and end position.
"""
@enum MotionType begin
    linewise
    exclusive # characterwise
    inclusive # characterwise
end

function (m::Motion)(s :: LE.MIState)
    buf = LE.buffer(s)
    seek(buf, m.stop)
end

function (m::Motion)(buf :: IOBuffer)
    seek(buf, m.stop)
end



# Motion(to :: TextObject) = Motion(to.start, to.stop)

min(motion :: Motion) = Base.min(motion.start, motion.stop)
max(motion :: Motion) = Base.max(motion.start, motion.stop)

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

function down(buf :: IOBuffer) :: Motion
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

function up(buf :: IOBuffer) :: Motion
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
function word_next(buf :: IOBuffer) :: Motion
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
    return Motion(start, endd)
end

"""
    The motion to the next big word, e.g. using the `W` command
"""
function word_big_next(buf :: IOBuffer) :: Motion
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
    return Motion(start, endd)
end


function word_end(buf :: IOBuffer) :: Motion
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
    return Motion(start, endd)
end

function word_back(buf :: IOBuffer) :: Motion
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
    return Motion(start, endd)
end

function word_big_back(buf :: IOBuffer) :: Motion
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
    return Motion(start, endd)
end

function word_big_end(buf :: IOBuffer) :: Motion
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
    return Motion(start, endd)
end

function line_end(buf :: IOBuffer) :: Motion
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
    return Motion(start, endd)
end

function line_begin(buf :: IOBuffer) :: Motion
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
    return Motion(start, endd)
end

"""
    The beginning of a line, including whitespace
"""
function line_zero(buf :: IOBuffer) :: Motion
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

function endd(buf :: IOBuffer) :: Motion

end

function find_c(buf :: IOBuffer, query_c :: Char) :: Motion
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
