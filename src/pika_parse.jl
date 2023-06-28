module PikaParse
import PikaParser as P
using Match
export well_formed, parse_command, synonym, partial_well_formed, eval_parse

const simple_motions = (
    'h',
    'l',
    'j',
    'k',
    'w',
    'W',
    'e',
    'E',
    'b',
    'B',
    '^',
    '$',
    '0',
    '{',
    '}',
    '(',
    ')',
    'G',
    'H',
    'L',
)


function parse_command(input::AbstractString)
    function ismotion(x)
        x in simple_motions
    end
    rules = Dict(
        :motion => P.satisfy(ismotion),
        :digits => P.some(P.satisfy(isdigit)),
        :register => P.seq(P.token('"'), P.satisfy(isletter)),
        :motions => P.seq(
            P.first(:register, P.epsilon),
            P.first(:digits, P.epsilon),
            :motion
        )
    )
    g = P.make_grammar(
        [:motions], # the top-level rule
        P.flatten(rules, Char), # process the rules into a single level and specialize them for crunching Chars
    )
    p = P.parse(g, input)
    # P.find_match_at!(p, :motions, 1)

end

function eval_parse(p::P.ParserState)
    function fold(m, p, subvals)
        # @info "Parsed values" m.rule m.view subvals
        # return nothing
        return @match m.rule begin
            :motion => m.view
            :digits => parse(Int, m.view)
            :register => m.view
        end
        # m.rule == :digits ? parse(Int, m.view) :
        # m.rule == :expr ? subvals[1] :
        # m.rule == :parens ? subvals[2] :
        # m.rule == :plusexpr ? subvals[1] + subvals[3] :
        # m.rule == :minusexpr ? subvals[1] - subvals[3] : nothing,
    end

    function open(match, parser)
        global m = match
        global p = parser
        @info "open" match.view match.rule match.first match.submatches
        (true for _ in match.submatches)
    end

    P.traverse_match(p, P.find_match_at!(p, :motions, 1), open=open)
end

end