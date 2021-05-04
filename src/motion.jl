struct Motion
    start :: Int64
    stop :: Int64
    motiontype
end

Motion(start :: Int64, stop :: Int64) = Motion(start, stop, nothing)
Motion(buf :: IOBuffer, change :: Int64) = Motion(position(buf), position(buf) + change)


"""
    A character motion is either inclusive or exclusive.  When inclusive, the
start and end position of the motion are included in the operation.  When
exclusive, the last character towards the end of the buffer is not included.
    Linewise motions always include the start and end position."""
@enum MotionType begin
    linewise
    exclusive # characterwise
    inclusive # characterwise
end

Motion(to :: TextObject) = Motion(to.start, to.stop)

min(motion :: Motion) = Base.min(motion.start, motion.stop)
max(motion :: Motion) = Base.max(motion.start, motion.stop)
Base.length(motion :: Motion) = max(motion) - min(motion)

# function word(s::LE.MIState)
#     buf = LE.buffer(s)
#     @log motion = word(buf)
#     @log action
#     (@eval $action)(buf, motion)
#     LE.refresh_line(s)
#     return true
# end

# function line(s::LE.MIState)
#     buf = LE.buffer(s)
#     @log motion = line(buf)
#     @log action
#     (@eval $action)(buf, motion)
#     LE.refresh_line(s)
#     return true
# end


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
function word(buf :: IOBuffer) :: Motion
    mark(buf)
    start = position(buf)

    eof(buf) && return Motion(start, start)
    last_c = read(buf, Char)
    while !eof(buf)
        c = read(buf, Char)
        if alphanumeric(last_c) && punctuation(c)
            break
        elseif punctuation(last_c) && alphanumeric(c)
            break
        elseif whitespace(last_c) && !whitespace(c)
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
function word_big(buf :: IOBuffer) :: Motion
    mark(buf)
    start = position(buf)

    eof(buf) && return Motion(start, start)
    last_c = read(buf, Char)
    while !eof(buf)
        c = read(buf, Char)
        if whitespace(last_c) && !whitespace(c)
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
    while !eof(buf) && position(buf) != start && whitespace(first_word_char)
        @log first_word_char = read(buf, Char)
    end

    while !eof(buf)
        c = read(buf, Char)
        if punctuation(first_word_char) && !punctuation(c)
            LE.char_move_left(buf)
            break
        elseif alphanumeric(first_word_char) && !alphanumeric(c)
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
        if alphanumeric(c) && punctuation(last_c)
            skip(buf, 1)
            break
        elseif punctuation(c) && alphanumeric(last_c)
            skip(buf, 1)
            break
        elseif whitespace(c) && !whitespace(last_c)
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

function word_back_big(buf :: IOBuffer) :: Motion
    start = position(buf)
    position(buf) == 0 && return Motion(start, start)

    skip(buf, -1)
    last_c = peek(buf, Char)

    while position(buf) > 0
        c = peek(buf, Char)
        if whitespace(c) && !whitespace(last_c)
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

function line_end(buf :: IOBuffer) :: Motion
    mark(buf)
    start = position(buf)

    while !eof(buf)
        c = read(buf, Char)
        if linebreak(c)
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
        if linebreak(c)
            break
        end
        if !whitespace(c)
            first_line_char = position(buf)
        end
    end
    if first_line_char == start
        skip(buf, 1)
        while !eof(buf)
            c = read(buf, Char)
            if !whitespace(c)
                skip(buf, -1)
                first_line_char = position(buf)
                break
            end
            if linebreak(c)
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
        if linebreak(c)
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


macro motion(k, fn, motion_type)
    return quote
        function $(esc(k))(buf::IOBuffer) :: Motion
            motion = $fn(buf)
            return motion
        end
    end
end
macro motion(k, fn)
    return quote
        function $(esc(k))(buf::IOBuffer) :: Motion
            motion = $fn(buf)
            return motion
        end
    end
end

# function motion(c :: Char)
#     name = get_safe_name(c)
#     map = Dict(
#         :h => (buf) -> Motion(position(buf), position(buf) - 1),# exclusive,
#         :l => (buf) -> Motion(position(buf), position(buf) + 1),# exclusive,
#         :w => word,# exclusive),
#         :e => word_end,# inclusive),
#         :b => word_back,# exclusive),
#         :caret => (buf -> Motion(position(buf), 0)),# exclusive)
#         :dollar => line_end,#inclusive)
#     )
#     fn = map[name]
#     return fn
# end

@motion(h, (buf) -> Motion(position(buf), position(buf) - 1), exclusive)
@motion(l, (buf) -> Motion(position(buf), position(buf) + 1), exclusive)
@motion(j, down)
@motion(k, up)
@motion(w, word, exclusive)
@motion(W, word_big, exclusive)
@motion(e, word_end, inclusive)
@motion(b, word_back, exclusive)
@motion(B, word_back_big, exclusive)
@motion(caret, line_begin, exclusive)
@motion(dollar, line_end, inclusive)


function (m::Motion)(s :: LE.MIState)
    buf = LE.buffer(s)
    seek(buf, m.stop)
end

function (m::Motion)(buf :: IOBuffer)
    seek(buf, m.stop)
end

