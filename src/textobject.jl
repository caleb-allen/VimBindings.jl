struct TextObject
    start :: Int64
    stop :: Int64
end


function line(buf :: IOBuffer) :: TextObject
    # find the line start
    mark(buf)
    if eof(buf)
        if position(buf) > 0
            LE.char_move_left(buf)
        end
    end

    while !eof(buf) && position(buf) > 0
        c = peek(buf, Char)
        if linebreak(c)
            skip(buf, 1)
            break
        end
        LE.char_move_left(buf)
    end
    start = position(buf)
    if ismarked(buf)
        reset(buf)
    end

    # find the line end
    mark(buf)
    while !eof(buf)
        c = read(buf, Char)
        if linebreak(c)
            LE.char_move_left(buf)
            break
        end
    end
    stop = position(buf)
    reset(buf)

    return TextObject(start, stop)
end



# Text helpers
linebreak(c::Char) = c in """\n"""
whitespace(c::Char) = c in """ \t\n"""
non_word(c::Char) = LE.is_non_word_char(c)
word_char(c::Char) = !LE.is_non_word_char(c)
punct_char(c::Char) = LE.is_non_word_char(c) && !is_non_phrase_char(c)

function alphanumeric(c :: Char) :: Bool
    return c in ['a':'z';
                 'A':'Z';
                 '0':'9';]
end

function alphabetic(c :: Char) :: Bool
    return c in ['a':'z';
                 'A':'Z';]
end

function is_uppercase(c :: Char) :: Bool
    return c in ['A':'Z';]
end
function is_lowercase(c :: Char) :: Bool
    return c in ['a':'z';]
end

function punctuation(c :: Char) :: Bool
    return c in """`!@#\$%^&*()-_=+[]{}'\"/?\\|<>,.:;"""
end


