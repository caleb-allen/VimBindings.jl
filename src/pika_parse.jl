module Parse
using ..Commands, ..Motions, ..Util

import PikaParser as P
import PikaParser: satisfy, seq, first, token, some, epsilon, flatten,
    make_grammar, find_match_at!, traverse_match, ParserState, scan
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

"""
    Parse `input` as a vim command.
"""
function parse_command(input::AbstractString)
    rules = Dict(
        # motion with oncluded count
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
            # rule to match a pair of equal tokens
            # :replace_command => seq(
            #     :count,
            #     token('r'),
            #     ϵ
            # )
        )
    )
    g = make_grammar(
        [:command], # the top-level rule
        flatten(rules, Char), # process the rules into a single level and specialize them for crunching Chars
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
        a = @match m.rule begin
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

end
