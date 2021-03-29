import VimBindings: verb_part, text_object_part, well_formed, parse_value, command, matched_rule, parse_command
using VimBindings.Commands

@testset "parse commands into parts" begin
    cmd = "d10w"
    @test well_formed(cmd) == true
    r = matched_rule(cmd)
    @test command(match(r, cmd)) == OperatorCommand(1,
                                                    'd',
                                                    10,
                                                    'w')


end

@testset "parse line operator commands" begin
    @test parse_command("5dd") == LineOperatorCommand(5,
                                                      'd')
    @test parse_command("100yy") == LineOperatorCommand(100,
                                                        'y')

    @test parse_command("100yd") === nothing
    @test parse_command("yy") === LineOperatorCommand(1, 'y')
end

@testset "parse motion commands" begin
    @test parse_command("l") == MotionCommand(1, 'l')
    @test parse_command("B") == MotionCommand(1, 'B')
    @test parse_command("^") == MotionCommand(1, '^')
    @test parse_command("10w") == MotionCommand(10, 'w')
end

