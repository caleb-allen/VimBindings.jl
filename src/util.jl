macro log(exs...)
    blk = Expr(:block)
    for ex in exs
        push!(blk.args, :(println(getsocket(), $(sprint(show_unquoted,ex)*" = "),
                                  repr(begin value=$(esc(ex)) end))))
    end
    isempty(exs) || push!(blk.args, :value)
    return blk
end

function log(s :: AbstractString)
    println(getsocket(), s)
end


# bind character to function
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

# alpha_keymap = AnyDict()

