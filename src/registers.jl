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