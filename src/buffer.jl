module Buffer
using Match
import REPL.LineEdit as LE
export VimBuffer, mode, VimMode, normal_mode, insert_mode, testbuf, readall, freeze,
    BufferRecord, chars, peek_left, peek_right, read_left, read_right

@enum VimMode begin
    normal_mode
    insert_mode
    # visual
end

function VimMode(s::AbstractString)
    return @match s begin
        "i" => insert_mode
        "n" => normal_mode
        _ => normal_mode
    end
end

VimMode(::Nothing) = normal_mode
VimMode(vm::VimMode) = vm

"""
    Generate a buffer from s, but place its position where the pipe operator occurs in `s`
    match | as the position of the buffer
    and match |i| as "insert mode", |n| as "normal mode".
    Defaults to normal mode.
"""
function testbuf(s::AbstractString)::VimBuffer
    m = match(r"(.*?)\|(?:([ni])\|)?(.*)"s, s)
    if m === nothing
        throw(ArgumentError("could not construct VimBuffer with string \"$s\"\n   Expecting a string with a pipe `|` indicating cursor position"))
    end
    (a, mode, b) = (m[1], m[2], m[3])
    buf = IOBuffer(; read=true, write=true, append=true)
    write(buf, a * b)
    seek(buf, length(a))
    vim_mode = VimMode(mode)
    return VimBuffer(buf, vim_mode)
end

struct VimBuffer <: IO
    buf::IOBuffer
    mode::VimMode
end

VimBuffer(str::String)::VimBuffer = testbuf(str)

mode(vb::VimBuffer) = vb.mode
# TODO modify VimBuffer operations to operate on Characters rather than bytes
Base.position(vb::VimBuffer) = position(vb.buf)
Base.seek(vb::VimBuffer, n) = seek(vb.buf, n)
Base.mark(vb::VimBuffer) = mark(vb.buf)
Base.peek(vb::VimBuffer, ::Type{T}) where {T} = peek(vb.buf, T)
Base.peek(vb::VimBuffer) = peek(vb.buf)
Base.reset(vb::VimBuffer) = reset(vb.buf)
Base.read(vb::VimBuffer, ::Type{Char}) = read(vb.buf, Char)
Base.read(vb::VimBuffer, ::Type{String}) = read(vb.buf, String)
Base.take!(vb::VimBuffer) = take!(vb.buf)
Base.eof(vb::VimBuffer) = eof(vb.buf)
Base.skip(vb::VimBuffer, o) = skip(vb.buf, o)
Base.truncate(vb::VimBuffer, n::Integer) = truncate(vb.buf, n)
Base.write(vb::VimBuffer, x::AbstractString) = write(vb.buf, x)
Base.write(vb::VimBuffer, x::Union{SubString{String},String}) = write(vb.buf, x)
Base.copy(vb::VimBuffer) = VimBuffer(copy(vb.buf), vb.mode)

"""
Read 1 valid UTF-8 character left of the current position and leave the buffer in the same position.
"""
function peek_left(buf::IO)::Union{Char,Nothing}
    origin = position(buf)
    while position(buf) > 0
        skip(buf, -1)
        c = peek(buf, Char)
        # skip(buf, -1)
        if isvalid(c)
            seek(buf, origin)
            return c
        end
    end
    seek(buf, origin)
    return nothing
end

"""
Read 1 valid UTF-8 character left of the current position.

Place the cursor before the char that is read, if any.
"""
function read_left(buf::IO)::Union{Char,Nothing}
    origin = position(buf)
    while position(buf) > 0
        skip(buf, -1)
        c = peek(buf, Char)
        # skip(buf, -1)
        if isvalid(c)
            return c
        end
    end
    seek(buf, origin)
    return nothing
end

"""
Read 1 valid UTF-8 character right of the current position and leave the buffer in the same position.
"""
function peek_right(buf::IO)::Union{Char, Nothing}
    origin = position(buf)
    while !eof(buf)
        c = read(buf, Char)
        if isvalid(c)
            seek(buf, origin)
            return c
        end
    end
    seek(buf, origin)
    return nothing
end

"""
Read 1 valid UTF-8 character right of the current position.

Place the cursor after the char that is read, if any.
"""
function read_right(buf::IO)::Union{Char, Nothing}
    origin = position(buf)
    while !eof(buf)
        c = read(buf, Char)
        if isvalid(c)
            return c
        end
    end
    seek(buf, origin)
    return nothing
end
function chars(vb::VimBuffer)::Vector{Char}
    collect(String(take!(copy(vb))))
end


function Base.getproperty(vb::VimBuffer, sym::Symbol)
    if sym === :size
        return vb.buf.size
    else # fallback to getfield
        return getfield(vb, sym)
    end
end

function Base.show(io::IO, buf::VimBuffer)
    # read all of vb into a string
    # reconstruct the "mode" style string, e.g.
    # "this is|i| a buffer in insert mode"
    pos = position(buf)
    text = String(take!(copy(buf)))
    # cs = chars(buf)
    s = if length(text) <= 0
        ""
    else
        # seekstart(buf)
        # read(buf, String)
    end
    # seek(buf, pos)
    a = text[begin:thisind(text, pos)]
    b = text[nextind(text, pos):end]
    mode = if buf.mode == insert_mode
        "i"
    elseif buf.mode == normal_mode
        "n"
    end

    out = a * "|$mode|" * b
    print(io, " VimBuffer(\"$out\")")
end
function Base.show(io::IO, ::MIME"text/plain", vb::VimBuffer)
    show(io, vb)
end


"""
Two VimBuffers are equal if their contents and position are equal
"""
function Base.:(==)(buf1::VimBuffer, buf2::VimBuffer)
    a = IOBuffer()
    b = IOBuffer()

    show(a, buf1)
    show(b, buf2)

    seekstart(a)
    seekstart(b)

    return read(a, String) == read(b, String)
end

end

