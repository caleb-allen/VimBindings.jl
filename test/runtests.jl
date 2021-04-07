# using VimBindings
import VimBindings: word_next, word_end, word_big_next, Motion, punctuation, find_c, line_begin
# import VimBindings: line, TextObject
using Test
# const VB = VimBindings

# include("action.jl")
include("parse.jl")
include("textutils.jl")
include("command.jl")
include("motion.jl")
include("textobject.jl")

@testset "VimBindings.jl" begin
end
@testset "motion.jl" begin
    #               0123456789
    #               |-----|
    buf = IOBuffer("Hello worl")
    motion = word_next(buf)
    @test motion == Motion(0, 6)

    @assert punctuation('-')
    buf = IOBuffer("Hello-worl")
    motion = word_next(buf)
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

@testset "big word" begin
    buf = IOBuffer("push!(LOAD_PATH, dirname(file))")
    motion = word_big_next(buf)
    @test motion == Motion(0, 17)
end

# @testset "begin big word" begin
#     buf = IOBuffer("push!(LOAD_PATH, dirname(file))")
#     seek(buf, 20)
#     @test motion == Motion(0, 17)
# end


@testset "find char" begin

    buf = IOBuffer("using VimBindings")
    @test find_c(buf, 'g') == Motion(0, 4)
end

@testset "line diffs" begin

end

@testset "line begin" begin
    s = """
First line
    second line
    third line
"""
    buf = IOBuffer(s)
    seek(buf, 17)
    # @show peek(buf)
    @test line_begin(buf) == Motion(17, 15)

    # in the second line's space
    seek(buf, 11)
    @test line_begin(buf) == Motion(11, 15)

    seek(buf, 4)
    @test line_begin(buf) == Motion(4, 0)
end

