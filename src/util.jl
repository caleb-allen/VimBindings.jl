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


function log(s...)
    println(getsocket(), s...)
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

