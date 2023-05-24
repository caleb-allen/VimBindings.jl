module Util
using Sockets
export @debug, getsocket, @debug, @loop_guard, TupleDict
import Base: show_unquoted

const MAX_LOOPS = 2^16

macro loop_guard(ex)
    @assert ex.head == :while
    loop_contents = ex.args[2]
    @assert loop_contents.head == :block

    loop_counter = gensym()
    source = QuoteNode(__source__)

    # ex is a while loop, so we insert this loop counter at the end,
    # with a check to make sure it doesn't exceed MAX_LOOPS:
    push!(loop_contents.args, :($loop_counter += 1))
    push!(
        loop_contents.args,
        :(
            $loop_counter > $MAX_LOOPS &&
            (@warn("Infinite loop detected at " * string($source) * ". Exiting."); break)
        ),
    )

    return esc(quote
        local $loop_counter = 0
        $ex
    end)
end

"""
Simple NamedTuple-like type allowing custom key types (like regex)
"""
struct TupleDict{T1<:Tuple,T2<:Tuple}
    keys::T1
    values::T2
end
TupleDict(d::AbstractDict) = TupleDict(Tuple(keys(d)), Tuple(values(d)))
TupleDict(pair::Pair...) = TupleDict(Tuple(first.(pair)), Tuple(last.(pair)))
Base.keys(d::TupleDict) = d.keys
Base.values(d::TupleDict) = d.values
function Base.getindex(d::TupleDict, k)
    i = findfirst(==(k), keys(d))
    i == 0 && error("key not found")
    return @inbounds(values(d)[i])
end



end
