

clauses = (
    :motions, :motion, :textobject, :findmotion, :repeat, :count, :register,
    :command
)
function clause(match, subvals)
    sym = match.rule
    @info "Executing clause $(string(sym))" match subvals
    if !(sym in clauses)
        @warn "$(match.rule) not an executable clause"
        return match.view
    end
    # TODO get the fields and save them to a const dict.
    f = getfield(Parse, sym)
    if !isempty(subvals) || isempty(match.view)
        f(subvals...)
    else
        f(match.view)
    end
end

function repeat(a::AbstractString)
    parse(Int, a)
end

count(repeat::Int) = repeat
count() = 1

motion(m::AbstractString) = m

motions(count::Int, motion::AbstractString) = SimpleMotionCommand(count, motion[1])

