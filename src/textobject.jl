module TextObjects
using Match
using ..TextUtils

abstract type Selection end

struct Inner <: Selection end
struct A <: Selection end

# abstract type TextObject end
struct TextObject{T <: Selection}

end

function textobject(buf :: IOBuffer, name :: String)
    m = match(r"^([ai])(.)$", name)
    selection = @match m[1] begin
        "i" => Inner()
        "a" => A()
    end

    object_fn :: Function = @match m[2] begin
        "w" => word
        _ => error("text object command not found: $(m[2])")
    end
    selection(object)
end



function inner()

end

"""
  For non-block objects: For the "a" commands: The operator applies to the object and the white space after the object. If there is no white space after the object or when the cursor was in the white space before the object, the white space before the object is included.
"""
function (::A)(object_function)
end

"""
For the "inner" commands: If the cursor was on the object, the operator applies to the object. If the cursor was on white space, the  operator applies to the white space.
"""
function (::Inner)(object_function)
end


"""
    The range
"""
# function word(buf :: IOBuffer) :: Union{UnitRange{Int}, Nothing}

# end

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

    return Motion(start, stop)
end

function word(buf :: IOBuffer) :: UnitRange{Int}
    start = position(buf)
    while position(buf) > 0
        if 
    end
    return start:endd
end

end
