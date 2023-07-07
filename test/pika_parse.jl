using VimBindings.Parse
using VimBindings.Commands
using AbstractTrees
import PikaParser as P
import PikaParser: satisfy, seq, first, token, some, epsilon, flatten,
    make_grammar, find_match_at!, traverse_match, ParserState, scan

@testset "pika parse" begin
    @test parse_command("5w") == MotionCommand(5, 'w')
    @test parse_command("10w") == MotionCommand(10, 'w')
end

@testset "partial rules" begin
    before = Parse.partial_rule(seq(token.(collect("abc"))...)) 
    
    after = first(
        token('a'),
        seq(token('a'), token('b')),
        seq(token('a'), token('b'), token('c')),
    )
    print_tree(before)
    print_tree(after)
    @test before == after
    rules = seq(
        token('a'),
        first(
            seq(token('b'), token('c')),
            seq(token('x'), token('y'))
        )
    )

    partialized = Parse.partial_rule(rules)
    result = first(
        token('a'),
        seq(
            token('a'),
            first(
                first(
                    token('b'),
                    seq(token('b'), token('c'))
                ),
                first(
                    token('x'),
                    seq(token('x'), token('y'))
                )
            )
        )
    )
    show(stdout, MIME"text/plain"(), result)
    show(stdout, MIME"text/plain"(), partialized)
    @test partialized == result
end

