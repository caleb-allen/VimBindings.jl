# include("../src/parse.jl")
# import VimBindings: verb_part, text_object_part, well_formed, parse_value
import VimBindings.Parse: verb_part, text_object_part, well_formed, parse_value

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
