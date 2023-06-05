"""
From vim :h registers:

There are ten types of registers:		*registers* *{register}* *E354*
1. The unnamed register ""
2. 10 numbered registers "0 to "9
3. The small delete register "-
4. 26 named registers "a to "z or "A to "Z
5. Three read-only registers ":, "., "%
6. Alternate buffer register "#
7. The expression register "=
8. The selection registers "* and "+
9. The black hole register "_
10. Last search pattern register "/

"""
module Registers

export get

const registers = Dict{Char, AbstractString}()

function __init__()
end

function Base.put!(reg :: Char, obj :: AbstractString)
    registers[reg] = obj
end

function Base.put!(::Nothing, obj :: AbstractString)
    reg = '"'
    put!(reg, obj) 
end

function Base.get(reg :: Char) :: Union{AbstractString, Nothing}
    if haskey(registers, reg) 
        return registers[reg]
    else
        return nothing
    end
end

function Base.get(nothing :: Nothing) :: Union{AbstractString, Nothing}
    return get('"')
end
end