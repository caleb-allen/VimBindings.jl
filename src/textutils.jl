module TextUtils
import Base: *
using REPL
include("buffer.jl")
using .Buffer
export VimBuffer, mode, VimMode, normal_mode, insert_mode, testbuf, readall, freeze, BufferRecord
const LE = REPL.LineEdit
export is_newline, is_whitespace, is_word_char, TextChar, WordChar, WhitespaceChar, PunctuationChar, ObjectChar,
    chars_by_cursor, junction_type, at_junction_type, Text, Object, Word, Line, Whitespace, Junction, Start, End, In,
    is_alphanumeric, is_alphabetic, is_uppercase, is_lowercase, is_punctuation, is_line_start, is_line_end,
    is_word_end, is_word_start, is_object_start, is_object_end, is_whitespace_end, is_whitespace_start, is_in_word

"""
    Determine whether the buffer is currently at the start of a text object.
    Whitespace is not included as a text object.
"""
is_word_start(buf) = at_junction_type(buf, Start{>:Word})
is_whitespace_start(buf) = at_junction_type(buf, Start{>:Whitespace})
"""
Whether the buffer is currently at the start of a non-whitespace
block
"""
is_object_start(buf) = at_junction_type(buf, Start{>:Object})

"""
    Whether the buffer is currently at the end of a text object. Whitespace is not included as a text object.
"""
is_word_end(buf) = at_junction_type(buf, End{>:Word})
is_object_end(buf) = at_junction_type(buf, End{>:Object})
is_whitespace_end(buf) = at_junction_type(buf, End{>:Whitespace})

"""
    Whether the buffer is at the start of a line, in the literal sense
    In other words, is the char before the cursor a newline
"""
is_line_start(buf) = at_junction_type(buf, Start{>:Line})
is_line_end(buf) = at_junction_type(buf, End{>:Line})


"""
Whether the buffer is currently in an object of a continuous type (not between two types)
"""
function is_in_word(buf)
    a, b = chars_by_cursor(buf)
    typeof(a) == typeof(b) || return false
    at_junction_type(buf, In{>:Word})
end

"""
Get the 
"""
function chars_by_cursor(buf::IO)::Tuple{Union{TextChar,Nothing},Union{TextChar,Nothing}}
    local c1
    local c0
    start_pos = position(buf)
    if eof(buf)
        c1 = nothing
    else
        mark(buf)
        c1 = read(buf, Char) |> TextChar
        reset(buf)
    end

    if start_pos == 0
        # beginning of buffer
        c0 = nothing
    else
        mark(buf)

        skip(buf, -1)
        c0 = read(buf, Char) |> TextChar
        reset(buf)
    end
    return (c0, c1)
end

abstract type Text end
# a textual object (non-whitespace). 
abstract type Object <: Text end
struct Word <: Object end
struct Whitespace <: Text end
struct Line <: Text end

abstract type Junction{T<:Text} end
struct Start{T<:Text} <: Junction{T} end
struct End{T<:Text} <: Junction{T} end
struct In{T<:Text} <: Junction{T} end


"""
    A character as understood within the context of a vim object
"""
abstract type TextChar end
# abstract type NonWordChar{T} <: TextChar{T} end
abstract type ObjectChar <: TextChar end

abstract type WhitespaceChar <: TextChar end

struct SpaceChar <: WhitespaceChar
    c::Char
end

struct NewlineChar <: WhitespaceChar
    c::Char
end

struct WordChar <: ObjectChar
    c::Char
end

struct PunctuationChar <: ObjectChar
    c::Char
end

Base.convert(::Type{Char}, c::TextChar) = c.c
Base.convert(::Type{TextChar}, c::Char) = TextChar(c)
Base.promote_rule(::Type{<:TextChar}, ::Type{Char}) = Char

*(a::TextChar, b::AbstractChar) = *(promote(a, b)...)


function TextChar(c::Char)
    return if is_newline(c)
        NewlineChar(c)
    elseif is_whitespace(c)
        SpaceChar(c)
    elseif is_word_char(c)
        WordChar(c)
    else
        PunctuationChar(c)
    end
end

"""
Describe the textobject characteristics of the junction of Text
comprised of `char1` and `char2`
"""
function junction_type(char1::TextChar, char2::TextChar)::Set{Junction}
    return Set{Junction}()
end

function junction_type(char1::Union{Char,Nothing}, char2::Union{Char,Nothing})
    arg1 = if char1 === nothing
        nothing
    else
        convert(TextChar, char1)
    end
    arg2 = if char2 === nothing
        nothing
    else
        convert(TextChar, char2)
    end
    junction_type(arg1, arg2)
end

function junction_type(text::AbstractString)
    length(text) != 2 && error("Cannot determined junction type for $text. Expected string with length 2, instead got $(length(text))")
    return junction_type(text[1], text[2])
end
junction_type(buf::IO) = junction_type(chars_by_cursor(buf)...)

junction_type(char1::Char, char2::Char) = junction_type(convert(TextChar, char1), convert(TextChar, char2))
junction_type(char1::Char, char2::Nothing) = junction_type(convert(TextChar, char1), char2)

junction_type(char1::Nothing, char2::Char) = junction_type(char1, convert(TextChar, char2))

junction_type(char1::Nothing, char2::Nothing) = Set([Start{Line}(), End{Line}()])
junction_type(char1::Nothing, char2::ObjectChar) = Set([Start{Line}(), Start{Object}()])

junction_type(char1::WhitespaceChar, char2::ObjectChar) = Set([Start{Object}(), End{Whitespace}()])
junction_type(char1::NewlineChar, char2::ObjectChar) = Set([Start{Line}(), Start{Object}()])

junction_type(char1::ObjectChar, char2::WhitespaceChar) = Set([End{Object}(), Start{Whitespace}()])
junction_type(char1::ObjectChar, char2::NewlineChar) = Set([End{Object}(), End{Line}()])

junction_type(char1::ObjectChar, char2::Nothing) = Set([End{Object}(), End{Line}()])

junction_type(char1::Nothing, char2::WhitespaceChar) = Set([Start{Whitespace}(), Start{Line}()])
junction_type(char1::WhitespaceChar, char2::Nothing) = Set([End{Whitespace}(), End{Line}()])

junction_type(char1::SpaceChar, char2::NewlineChar) = Set([End{Whitespace}(), End{Line}()])
junction_type(char1::NewlineChar, char2::SpaceChar) = Set([Start{Line}(), Start{Whitespace}()])

junction_type(char1::Nothing, char2::NewlineChar) = Set([Start{Line}(), End{Line}()])
junction_type(char1::NewlineChar, char2::Nothing) = Set([Start{Line}()])

junction_type(char1::WordChar, char2::PunctuationChar) = Set([Start{Word}(), End{Word}()])
junction_type(char1::PunctuationChar, char2::WordChar) = Set([Start{Word}(), End{Word}()])

junction_type(char1::T, char2::T) where {T<:ObjectChar} = Set([In{Word}()])
junction_type(char1::T, char2::T) where {T<:SpaceChar} = Set([In{Whitespace}()])

"""
Whether the given buffer is currently at a junction of type junc
"""
function at_junction_type(buf, junc_type)
    for junc in junction_type(buf)
        if junc isa junc_type
            return true
        end
    end
    return false
end
# Text helpers
is_newline(c::Char) = c == '\n'
is_whitespace(c::Char) = isspace(c)
# non_word(c::Char) = LE.is_non_word_char(c)
is_word_char(c::Char) = is_alphanumeric(c) || isletter(c) || c == '_'
# punct_char(c::Char) = LE.is_non_word_char(c) && !is_non_phrase_char(c)

function is_alphanumeric(c::Char)::Bool
    return c in ['a':'z'
        'A':'Z'
        '0':'9']
end

function is_alphabetic(c::Char)::Bool
    return c in ['a':'z'
        'A':'Z']
end

function is_uppercase(c::Char)::Bool
    return c in ['A':'Z';]
end
function is_lowercase(c::Char)::Bool
    return c in ['a':'z';]
end

function is_punctuation(c::Char)::Bool
    return ispunct(c)
    # return c in """`!@#\$%^&*()-_=+[]{}'\"/?\\|<>,.:;"""
end

function is_unicode_letter(c::Char)::Bool
    return isletter(c)
end


end
