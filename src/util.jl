module Util
using Sockets
export log, getsocket, @log, @loop_guard
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

macro log(exs...)
    blk = Expr(:block)
    loc = string("\t", __source__.file, "#", __source__.line)
    for ex in exs
        push!(blk.args, :(println(getsocket(),
                                  $(sprint(show_unquoted,ex)*" = "),
                                  repr(begin value=$(esc(ex)) end),
                                  "\n",
                                  $loc,
                                  "\n",
                                  )))
    end
    isempty(exs) || push!(blk.args, :value)
    return blk
end

# macro log(str)
#     blk = Expr(:block)
#     loc = string("\t", __source__.file, "#", __source__.line)
#     push!(blk.args, :(println(getsocket(),
#                               # repr(begin value=$(esc(str)) end),
#                               $str,
#                               "\n",
#                               $loc,
#                               "\n",
#                               )))
#     push!(blk.args, :value)
#     return blk
# end


# TODO this is terrible to overload
function Base.log(s...)
    println(getsocket(), s...)
end

function __init__()
    global socket = devnull
end
function enable_logging()
    global socket = connect(1234)
end

function getsocket()
    return socket
end

function Base.log(any::Any)
    socket = getsocket()
    println(socket, any)
end


function test_bind()

end

# 'j' => (s::LE.MIState, o...)->LE.edit_move_down(s),

macro bindkey(c)
    # char = ($(esc(c)))
    # char = esc(c)
    # @show sym = Symbol(char)
    return :(
        ()->eval(Expr(:call, Symbol($(esc(c))))))
         # pair item 2
         # (s::LE.MIState, o...)->begin
         # @show Symbol($(esc(c)))
         # Expr(:call, Symbol($(esc(c))),(VB.mode, esc(s)))
end

# buffer(s :: LE.MIState) = LE.buffer(s)

# alpha_keymap = AnyDict()

end
