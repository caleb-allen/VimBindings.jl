using VimBindings.Motion
import VimBindings.Motion: word, WORD
using VimBindings.TextUtils
@testset "a word textobject" begin
    @test word(testbuf("|word")) == (0, 4)
    @test word(testbuf("|word word")) == (0, 4)
    @test word(testbuf("|word#@!")) == (0, 4)
    @test word(testbuf("|word !##@")) == (0, 4)
    @test word(testbuf("|!##@ word")) == (0, 4)
    @test word(testbuf("|!##@word")) == (0, 4)

    @test word(testbuf("word|!##@")) == (5, 8)
end

@testset "a WORD textobject" begin
    @test WORD(testbuf("|word !##@")) == (0, 4)
    @test WORD(testbuf("|word!##@ ")) == (0, 8)
    @test WORD(testbuf("|word#@!")) == (0, 7)
end

@testset "space textobject" begin
    # @test space(testbuf("|    ")) == (0, 3)
    # @test space(testbuf("this|  space")) == (4, 5)
    # @test space(testbuf("this | space")) == (4, 5)
    # @test space(testbuf("this  |space")) == (6, 6)
end
