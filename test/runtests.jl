using VimBindings
import VimBindings: word, word_end, Motion, punctuation, find_c
import VimBindings: line, TextObject
using Test
const VB = VimBindings

# include("action.jl")
include("parse.jl")
include("command.jl")
#=
@testset "VimBindings.jl" begin
end
@testset "motion.jl" begin
    #               0123456789
    #               |-----|
    buf = IOBuffer("Hello worl")
    motion = word(buf)
    @test motion == Motion(0, 6)

    @assert punctuation('-')
    buf = IOBuffer("Hello-worl")
    motion = word(buf)
    @test motion == Motion(0, 5)

end

@testset "word end" begin

    buf = IOBuffer("using VimBindings")
    @test word_end(buf) == Motion(0, 4)

    motion = word_end(IOBuffer("VimBindings.jl"))
    @test motion == Motion(0, 10)

    motion = word_end(IOBuffer(" VimBindings.jl"))
    @test motion == Motion(0, 11)
end

@testset "find char" begin

    buf = IOBuffer("using VimBindings")
    @test find_c(buf, 'g') == Motion(0, 4)
end

@testset "line diffs" begin

end

@testset "line motion" begin
    s = """
First line
second line
third line
"""
    buf = IOBuffer(s)
    @test line(buf) == TextObject(0, 10)
end


=#
