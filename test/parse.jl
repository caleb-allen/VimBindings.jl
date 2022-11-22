# include("../src/parse.jl")
# import VimBindings: verb_part, text_object_part, well_formed, parse_value
import VimBindings.Parse: verb_part, text_object_part, well_formed, parse_value
using VimBindings.Commands
using VimBindings.Parse
import VimBindings.Parse: command


# @testset "is operator" begin
#     @test is_operator("y") == false
#     @test is_operator("yw") == true
#     @test is_operator("d") == false
#     @test is_operator("d22w") == true
#     @test is_operator("diw") == true
#     @test is_operator("yW") == true
#     @test is_operator("4yW") == true
#     @test is_operator("10D") == false
#     @test is_operator("10d") == false
# end

# @testset "simple motions" begin
#     @test is_motion("w") == true
#     @test is_motion("5b") == true
#     @test is_motion("10h") == true
#     @test is_motion("4j") == true
#     @test is_motion("3w") == true
#     # @test is_motion("d3w") == false
# end


@testset "verbs from strings" begin
    @test verb_part("dw") == 'd'
    @test verb_part("y") == 'y'
    @test verb_part("yw") == 'y'
    @test verb_part("d") == 'd'
    @test verb_part("d22w") == 'd'
    @test verb_part("diw") == 'd'
    @test verb_part("cW") == 'c'
    @test verb_part("10D") == nothing
    @test verb_part("10d") == 'd'
end

@testset "text objects" begin
    @test text_object_part("daw") == "aw"
    @test text_object_part("ciw") == "iw"
    @test text_object_part("aw") == "aw"
    @test text_object_part("yap") == "ap"
    @test text_object_part("yep") == nothing
    @test text_object_part("yappity") == nothing

end
@testset "validating commands" begin
    @test well_formed("daw") == true
    @test well_formed("aw") == false
    @test well_formed("5d5w5") == false
    @test well_formed("dd") == true
    @test well_formed("yy") == true
    @test well_formed("5dd") == true
    @test well_formed("yy") == true
    @test well_formed("yd") == false
    @test well_formed("cd") == false

    @test well_formed("h") == true
    @test well_formed("l") == true
    @test well_formed("5l") == true
    @test well_formed("4h") == true

    @test well_formed("10dd") == true
end

@testset "parse specific values" begin
    @test parse_value("10") == 10
    @test parse_value("d") == 'd'
    @test parse_value("aw") == "aw"
    @test parse_value(nothing) == nothing
end

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

@testset "parse singular commands" begin
    @test parse_command("x") == OperatorCommand(1, 'd', 1, 'l')
    @test parse_command("X") == OperatorCommand(1, 'd', 1, 'h')
    @test parse_command("4x") == OperatorCommand(4, 'd', 1, 'l')
end
