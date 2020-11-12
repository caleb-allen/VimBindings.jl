macro log(exs...)
    blk = Expr(:block)
    for ex in exs
        push!(blk.args, :(println(getsocket(), $(sprint(show_unquoted,ex)*" = "),
                                  repr(begin value=$(esc(ex)) end))))
    end
    isempty(exs) || push!(blk.args, :value)
    return blk
end
