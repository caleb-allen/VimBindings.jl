struct Motion
    start :: Int64
    stop :: Int64
end

Motion(to :: TextObject) = Motion(to.start, to.stop)
# TODO add 'inclusive' param

min(motion :: Motion) = Base.min(motion.start, motion.stop)
max(motion :: Motion) = Base.max(motion.start, motion.stop)
length(motion :: Motion) = max(motion) - min(motion)

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
    return @log Motion(start, endd)
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


