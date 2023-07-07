module Parse
using ..Commands, ..Motions, ..Util

import PikaParser as P
import PikaParser: satisfy, seq, first, token, some, epsilon, flatten,
    make_grammar, find_match_at!, traverse_match, ParserState, scan,
    Scan, Token, Tokens, Epsilon, Fail, Seq, First, Some, Many
using Match
export well_formed, parse_command, synonym, partial_well_formed, eval_parse
include("parse_clauses.jl")
using .ParseClauses

const ϵ = epsilon

function ismotion(x)
    x in keys(simple_motions)
end

function islineoperator(m)
    length(m) != 2 && return -1
    m[1] == m[2] ? 2 : -1
end

function rules()
    Dict( # motion with oncluded count
        :motions => seq(
            # :repeat,
            :count,
            :motion => satisfy(ismotion)
        ),
        :textobject => seq(
            :count,
            P.first(token.(['a', 'i'])...),
            P.first(token.(['w', 'W', 's', 'p'])...)
        ),
        :operator => P.first(
            token.(['d', 'y', 'c'])...
        ),
        :operators => seq(
            :count,
            :operator
        ),
        :findmotions => seq(
            :count,
            # P.first(token.(['f', 'F', 't', 'T'])...)
            P.first(token.(collect("fFtT"))...)
        ), :repeat => some(satisfy(isdigit)),
        # like "repeat" but may be missing
        :count => P.first(:repeat, ϵ),
        # :register => seq(token('"'), satisfy(isletter)),
        :textobject_command => seq(
            :operators,
            :textobject
        ),
        :motion_command => seq(
            P.first(:motions, :findmotions)
        ),
        :operator_command => seq(
            :operators,
            P.first(:motion_command, :textobject_command)
        ),
        :command => P.first(
            :insert_command => P.first(
                token.(collect("aAiIoO"))...
            ),
            :zero_command => token('0'),
            :synonym_command => seq(
                :count,
                :synonym => P.first(token.(collect("xXDCS"))...)
            ),
            :history_command => seq(
                :count,
                :history => P.first(token('u'), token('\x12')),
            ),
            :motion_command,
            :textobject_command,
            :operator_command,
            :lineoperator_command => seq(
                :count,
                scan(islineoperator)
            ),
            :replace_command => seq(
                :count,
                token('r'),
                :char => satisfy(c->true),
            ),
        )
    )
end

"""
    Parse `input` as a vim command.
"""
function parse_command(input::AbstractString)
    g = make_grammar(
        [:command], # the top-level rule
        flatten(rules(), Char), # process the rules into a single level and specialize them for crunching Chars
    )
    p = P.parse(g, input)
    eval_parse(p)
    # find_match_at!(p, :command, 1)

end


function eval_parse(p::ParserState)
    function fold(m, p, subvals)
        # @info string(m.rule) m.rule m.view subvals
        # dump(subvals)
        # return nothing
        # @info string(m.rule) m.rule m.view subvals
        # dump(m)
        a = clause(m, subvals)
        @debug "Result for :$(string(m.rule))" result = a
        println("\n")
        return a
        #=a = @match m.rule begin
            :motions => MotionCommand()
            :motion => m.view
            :textobject => nothing
            :findmotion => nothing
            :repeat => parse(Int, m.view)
            :count => nothing,
            # :repeat => nothing
            # :register => m.view
            :register => nothing
            :command => nothing
        end
        if a === nothing
            a = m.view
        end
        @info "Result $(string(m.rule))" result = a
        println()
        return a
        =#
        # m.rule == :repeat ? parse(Int, m.view) :
        # m.rule == :expr ? subvals[1] :
        # m.rule == :parens ? subvals[2] :
        # m.rule == :plusexpr ? subvals[1] + subvals[3] :
        # m.rule == :minusexpr ? subvals[1] - subvals[3] : nothing,
    end

    function open(match, parser)

        response = (true for _ in match.submatches) |> collect
        @debug "open" match.view match.rule match.first match.submatches response
        @debug "parser data" typeof(parser) propertynames(parser) parser.matches parser.submatches
        return response
    end

    result = traverse_match(p, find_match_at!(p, :command, 1), fold=fold)
    result isa Command || @error("Got a $(typeof(result)) but expected <:Command. Folding may be incomplete.", result)
    return result
    # traverse_match(p, find_match_at!(p, :motions, 1), fold=fold)
end


"""
Take the rules and generate a list of rules which allows for partial matches.

    This takes any Seq and generates a match for each possible sub-sequence.
    e.g. "abc" -> "a", "ab", "abc"
"""
function partial_rules(rs::Dict{Symbol, P.Clause{G, Any} where G}=rules())::Dict{Symbol, P.Clause}
    for (name, rule) in rs
        # @info "unflattened" name rule
        rs[name] = partial_rule(name, rule)
    end
    # rules = flatten(rs, Char)
    rs
    # for (name, rule) in rules
    #     @info "flat" name rule
    # end
end

partial_rule(name::Symbol, c::P.Clause) = partial_rule(c)
partial_rule(p::Pair) = partial_rule(p...)
partial_rule(p::Tuple) = partial_rule(p...)

"""
Generate a rule which will progressively match `rule`
e.g. "abc" becomes "a", "ab", "abc"
"""
function partial_rule end

function partial_rule(rule::P.Seq)
    pc = map(partial_rule, rule.children) 
    # partial children
    
    # for i in 1:length(rule.children)
    sub_rules = []
    for i in 1:length(rule.children)
        # child = pc[j]
        # r = i == 1 ? pc[i] : seq(pc[1:i]...)
        # for j in 1:i
            r = if i == 1
                pc[i]
            else
                seq(pc[1:i]...)
            end
            # push!(sub_rules, r)
            # @info "increment" i j pc[1:j] r
            @info "increment" i pc[1:i] r
        # end
        push!(sub_rules, r)
        # @info "new subrule" i old=pc[i] new=sub_rule
        # push!(partialized_children, partialized_child)
    end
    # push!(pc, first(sub_rules...))
    # end
    new_rule = first(sub_rules...)
    @info "sequence rule" old_rule=rule new_rule
    return new_rule
end

function partial_rule(x::P.Terminal)
    # @info "terminal rule. Not changing." x
    x
end

function partial_rule(x::Symbol)
    # @info "symbol rule. Not changing." x
    x
end

# partial_rule(x::P.Seq)
# Clauses with children
partial_rule(rule::First) = first(map(partial_rule, rule.children)...)

partial_rule(rule::Some) = some(partial_rule(rule.item))
partial_rule(rule::Many) = many(partial_rule(rule.item))
partial_rule(rule::Epsilon) = ϵ

function well_formed(input::String)
    g = make_grammar(
        [:command], # the top-level rule
        flatten(rules(), Char), # process the rules into a single level and specialize them for crunching Chars
    )
    p = P.parse(g, input)
    match = find_match_at!(p, :command, 1)
    # result = traverse_match(p, find_match_at!(p, :command, 1))
    # eval_parse(p)
    # find_match_at!(p, :command, 1)

end

function well_formed(input::String)
    g = make_grammar(
        [:command], # the top-level rule
        flatten(rules(), Char), # process the rules into a single level and specialize them for crunching Chars
    )
    p = P.parse(g, input)
    match = find_match_at!(p, :command, 1)
    # result = traverse_match(p, find_match_at!(p, :command, 1))
    # eval_parse(p)
    # find_match_at!(p, :command, 1)

end

# function partial_well_formed(cmd::String)
#     prs = partial_rules()
#     g = make_grammar(
#         [:command],
#         flatten(prs, Char)
#     )
#     p = P.parse(g, cmd)
#     result = traverse_match(p, find_match_at!(p, :command, 1))
# end

end
