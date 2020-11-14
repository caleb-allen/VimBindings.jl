struct Motion
    start :: Int64
    stop :: Int64
end

# function test()
#     #               0123456789
#     #               |-----|
#     buf = IOBuffer("Hello worl")
#     motion = word(buf)
#     @assert motion == Motion(0, 6)


#     @assert punctuation('-')
#     buf = IOBuffer("Hello-worl")
#     motion = word(buf)
#     @assert motion == Motion(0, 5)
# end

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

function line(buf :: IOBuffer) :: Motion
    mark(buf)
    start = position(buf)

    while !eof(buf)
        c = read(buf, Char)
        if line_break(c)
            break
        end
    end
    skip(buf, -1)
    endd = positiopn(buf)
    reset(buf)
    return Motion(start, endd)
end

function endd(buf :: IOBuffer) :: Motion

end


line_break(c::Char) = c in """\n"""
whitespace(c::Char) = c in """ \t\n"""
non_word(c::Char) = LE.is_non_word_char(c)
word_char(c::Char) = !LE.is_non_word_char(c)
punct_char(c::Char) = LE.is_non_word_char(c) && !is_non_phrase_char(c)

function alphanumeric(c :: Char) :: Bool
    chars = ['a':'z';
             'A':'Z';
             '0':'9';]
    return c in chars
end
function punctuation(c :: Char) :: Bool
    return c in """`!@#\$%^&*()-_=+[]{}'\"/?\\|<>,.:;"""
end


