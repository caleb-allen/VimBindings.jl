# include("../src/parse.jl")
# import VimBindings: verb_part, text_object_part, well_formed, parse_value
import VimBindings.Parse: verb_part, text_object_part, well_formed, partial_well_formed, parse_value
using VimBindings.Commands
import VimBindings.Commands: ParseValue
using VimBindings.Parse
import VimBindings.Parse: command, parse_command


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


@testset "parse values" begin
    @test Parse.parse_value("10") == ParseValue(10)
    @test Parse.parse_value("0") == ParseValue(0)
    @test Parse.parse_value(".") == ParseValue('.')
    @test Parse.parse_value("asdf") == ParseValue("asdf")
    @test Parse.parse_value("10ten") == ParseValue("10ten")
end
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
    well_formed_cmds = (
        "daw", "dd", "yy", "5dd", "yy", "h", "l", "5l", "4h", "10dd"
    )
    poorly_formed_cmds = (
        "aw", "5d5w5", "yd", "cd"
    )
    @testset "Well formed commands" begin
        for cmd in well_formed_cmds
            @test well_formed(cmd) || @show cmd
        end
        for cmd in poorly_formed_cmds
            @test !well_formed(cmd) || @show cmd
        end
    end
    @testset "Partially well formed commands" begin
        for cmd in well_formed_cmds
            length(cmd) <= 1 && continue
            for cmd_end in 2:length(cmd)
                cmd_stub = cmd[1:cmd_end]
                @test partial_well_formed(cmd_stub) || @show cmd_stub
            end
        end
        # TODO: Remove these when the commands are implemented:
        @test !partial_well_formed("u")
        @test !partial_well_formed("m")
        @test !partial_well_formed("M")
        @test !partial_well_formed("*")
        @test !partial_well_formed("V")
        @test !partial_well_formed("daa")
        @test partial_well_formed("y")
        @test !partial_well_formed("yp")
        @test partial_well_formed("500dd")
        @test partial_well_formed("500d")
        @test partial_well_formed("500")
    end
end


@testset "parse specific values" begin
    @test parse_value("10") == ParseValue(10)
    @test parse_value("") == ParseValue(nothing)
    @test parse_value("d") == ParseValue('d')
    @test parse_value("aw") == ParseValue("aw")
    @test parse_value(nothing) == ParseValue(nothing)
end

@testset "parse commands into parts" begin
    cmd = "d10w"
    @test well_formed(cmd) == true
    r = matched_rule(cmd)
    @test parse_command(cmd) == OperatorCommand(1,
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

    a = parse_command("fd")
    b = MotionCommand(1, "fd", ('d',))
    #@show a, b
    #@show a.captures b.captures
    #@show typeof(a.captures) typeof(b.captures)
    #@show a.name == b.name
    #@show typeof(a.name) typeof(b.name)
    #@show a.r1 == b.r1
    #@show a.captures == b.captures
    #@show a == b
    @test parse_command("fd") == MotionCommand(1, "fd", ('d',))
end

@testset "parse singular commands" begin
    @test parse_command("x") == SynonymCommand(1, 'x')
    @test synonym(parse_command("x")) == OperatorCommand(1, 'd', 1, 'l')
    @test parse_command("X") == SynonymCommand(1, 'X')
    @test synonym(parse_command("X")) == OperatorCommand(1, 'd', 1, 'h')
    @test parse_command("4x") == SynonymCommand(4, 'x')
    @test synonym(parse_command("4x")) == OperatorCommand(4, 'd', 1, 'l')
end

@testset "parse complex commands" begin
    @test parse_command("dtl") == OperatorCommand(1, 'd', 1, "tl", 'l')
    @test parse_command("dtl") == OperatorCommand(1, 'd', 1, "tl", 'l')
end

@testset "parse replace command" begin
    @test parse_command("rx") == ReplaceCommand(1, 'x')
    @test parse_command("r%") == ReplaceCommand(1, '%')
    @test parse_command("5rx") == ReplaceCommand(5, 'x')
    @test parse_command("r5") == ReplaceCommand(1, '5')
    @test parse_command("10rx") == ReplaceCommand(10, 'x')
end
