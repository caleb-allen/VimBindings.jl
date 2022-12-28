# using VimBindings
import VimBindings: word_next, word_end, word_big_next, Motion, is_punctuation, find_c, line_begin
# import VimBindings: line, TextObject
using Test
# const VB = VimBindings

# include("action.jl")
include("parse.jl")
include("textutils.jl")
include("command.jl")
include("motion.jl")
include("textobject.jl")
include("registers.jl")

@testset "VimBindings.jl" begin
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

