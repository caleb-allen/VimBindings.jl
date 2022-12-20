module TextUtils
import Base: *
using REPL
const LE = REPL.LineEdit
export is_linebreak, is_whitespace, is_word_char, TextChar, WordChar, WhitespaceChar, PunctuationChar, ObjectChar
export is_alphanumeric, is_alphabetic, is_uppercase, is_lowercase, is_punctuation
export is_object_end, is_object_start, is_non_whitespace_start, is_non_whitespace_end,  is_whitespace_end, is_whitespace_start
export testbuf

"""
    Determine whether the buffer is currently at the start of a text object.
    Whitespace is not included as a text object.
"""
function is_object_start(buf)
    eof(buf) && return false
    start_pos = mark(buf)
    c1 = read(buf, Char) |> TextChar

    reset(buf)

    if c1 isa ObjectChar && start_pos == 0
        # beginning of line
        return true
    end

    mark(buf)

    skip(buf, -1)
    c2 = read(buf, Char) |> TextChar

    if c1 isa ObjectChar && typeof(c1) != typeof(c2)
        reset(buf)
        return true
    end
    return false
end

function is_whitespace_start(buf)
    eof(buf) && return false
    start_pos = mark(buf)
    c1 = read(buf, Char) |> TextChar

    reset(buf)

    if c1 isa WhitespaceChar && start_pos == 0
        # beginning of line
        return true
    end

    mark(buf)

    skip(buf, -1)
    c2 = read(buf, Char) |> TextChar

    if !(c1 isa WhitespaceChar) && c2 isa WhitespaceChar
        reset(buf)
        return true
    end
    return false
end


"""
Whether the buffer is currently at the start of a non-whitespace
block

"""
function is_non_whitespace_start(buf)
    eof(buf) && return false
    start_pos = mark(buf)
    c1 = read(buf, Char) |> TextChar

    reset(buf)

    if c1 isa ObjectChar && start_pos == 0
        # beginning of line
        return true
    end

    mark(buf)

    skip(buf, -1)
    c2 = read(buf, Char) |> TextChar

    if c1 isa WhitespaceChar && !(c2 isa WhitespaceChar)
        reset(buf)
        return true
    end
    return false
end


"""
    Whether the buffer is currently at the end of a text object. Whitespace is not included as a text object.
"""
function is_object_end(buf)
    eof(buf) && return false
    mark(buf)

    c1 = read(buf, Char) |> TextChar

    if eof(buf)
        reset(buf)
        return c1 isa ObjectChar
    end
    c2 = read(buf, Char) |> TextChar

    if c1 isa ObjectChar && typeof(c1) != typeof(c2)
        reset(buf)
        return true
    end
    reset(buf)
    return false
end

function is_non_whitespace_end(buf)
    eof(buf) && return false
    mark(buf)

    c1 = read(buf, Char) |> TextChar

    if eof(buf)
        reset(buf)
        return c1 isa ObjectChar
    end
    c2 = read(buf, Char) |> TextChar

    if !(c1 isa WhitespaceChar) && c2 isa WhitespaceChar
        reset(buf)
        return true
    end
    reset(buf)
    return false
end


function is_whitespace_end(buf)
    eof(buf) && return false
    mark(buf)

    c1 = read(buf, Char) |> TextChar

    if eof(buf)
        reset(buf)
        return c1 isa WhitespaceChar
    end
    c2 = read(buf, Char) |> TextChar

    if c1 isa WhitespaceChar && !(c2 isa WhitespaceChar)
        reset(buf)
        return true
    end
    reset(buf)
    return false
end

"""
    Generate a buffer from s, but place its position where the pipe operator occurs in `s`
"""
function testbuf(s :: AbstractString) :: IOBuffer
    a, b = split(s, '|')
    buf = IOBuffer(a * b)
    seek(buf, length(a))
    return buf
end


"""
    A character as understood within the context of a vim object
"""
abstract type TextChar{T <: Char} end
# abstract type NonWordChar{T} <: TextChar{T} end
abstract type ObjectChar{T} <: TextChar{T} end

struct WhitespaceChar{T} <: TextChar{T}
    c :: T
end

struct WordChar{T} <: ObjectChar{T}
    c :: T
end

struct PunctuationChar{T} <: ObjectChar{T}
    c :: T
end

Base.convert(::Type{Char}, c::TextChar{Char}) = c.c
Base.promote_rule(::Type{<:TextChar}, ::Type{Char}) = Char

*(a::TextChar, b::AbstractChar) = *(promote(a, b)...)


function TextChar(c::T) where T <: Char
    return if is_whitespace(c)
        WhitespaceChar(c)
    elseif is_word_char(c)
        WordChar(c)
    elseif is_punctuation(c)
        PunctuationChar(c)
    else
        error("Char '$c' cannot be described by a TextChar")
    end
end

# Text helpers
is_linebreak(c::Char) = c in """\n"""
is_whitespace(c::Char) = c in """ \t\n"""
# non_word(c::Char) = LE.is_non_word_char(c)
is_word_char(c::Char) = is_alphanumeric(c) || c == '_'
# punct_char(c::Char) = LE.is_non_word_char(c) && !is_non_phrase_char(c)

function is_alphanumeric(c :: Char) :: Bool
    return c in ['a':'z';
                 'A':'Z';
                 '0':'9';]
end

function is_alphabetic(c :: Char) :: Bool
    return c in ['a':'z';
                 'A':'Z';]
end

function is_uppercase(c :: Char) :: Bool
    return c in ['A':'Z';]
end
function is_lowercase(c :: Char) :: Bool
    return c in ['a':'z';]
end

function is_punctuation(c :: Char) :: Bool
    return c in """`!@#\$%^&*()-_=+[]{}'\"/?\\|<>,.:;"""
end


end
