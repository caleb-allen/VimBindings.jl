module Util
export @loop_guard

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
end
