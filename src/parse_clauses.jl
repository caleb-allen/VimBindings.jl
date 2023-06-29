"""
The functions for the parser to call to fold a parse rule

the first argument of a clause function is the match.view
the subsequent arguments are the subvalues

All methods in this module except `clause` and `clauses` MUST be for
    parsing a clause as defined in VimBindings.Parse
"""
module ParseClauses

using ..Motions, ..Commands
export clause

# TODO make this a const value
"""
    Get the methods in this
"""
function clauses()
    all_names = names(ParseClauses, all=true)
    filter(setdiff(all_names,
        (:ParseClauses, Symbol("#eval"), Symbol("#include"),
                :clause, :clauses, :eval))) do fn_name
        !startswith(string(fn_name), "#")
    end
end
# clauses = [x for x in names(ParseClauses, all=true) if getproperty(ParseClauses,x) isa Function && x ∉ (:eval, :include)]
function clause(match, subvals)
    sym = match.rule
    sym = Symbol(replace(string(match.rule), "-" => "_"))
    # dump(match)
    # e.g. motion-1 becomes motion_1
        # @debug "Executing clause $(string(sym))" match.view subvals
    if !(sym in clauses())
        @warn "No function for clause: `$sym` does not exist" f_name=sym args=(match.view, subvals...) types=typeof.(subvals)
        if !isempty(subvals)
            if length(subvals) == 1
                return subvals[1]
            else
                error("Ambigous clause: can't fold match with $(length(subvals)) subvals.")
            end
            return subvals
        end
        return match.view
    else
        @debug "Clause `$sym`" f_name=sym args=(match.view,subvals...) types=typeof.(subvals)
    end
    # TODO get the fields and save them to a const dict.
    f = getfield(ParseClauses, sym)
    return f(match.view, subvals...)
end

repeat(a::AbstractString, args...) = parse(Int, a)

count(_, repeat::Int) = repeat

count(_) = 1

motion(m::AbstractString) = m[1]

motions(_, count::Int, name::AbstractChar) = SimpleMotionCommand(count, name)

operator(_, name::AbstractString) = name[1]

operators(_, count::Int, name::Char) = (count, name)

operator_command(_, op::Tuple{Int, AbstractChar}, cmd::Union{MotionCommand, TextObjectCommand}) = 
    OperatorCommand(op[1], op[2], cmd)

textobject(_, count::Int, a_or_i::AbstractString, object_type::AbstractString) =
    (count, a_or_i[1], object_type[1])
    
textobject_command(_,
                    op::Tuple{Int, Char},
                    textobject::Tuple{Int, Char, Char}) =
    OperatorCommand(
        op[1], op[2],
        # TODO separate name into two char parts
        TextObjectCommand(textobject[1], textobject[2] * textobject[3])
    )
end