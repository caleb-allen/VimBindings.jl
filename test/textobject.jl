using VimBindings.TextObjects
using VimBindings.TextUtils
@testset "a word textobject" begin
    @test word(testbuf("|word")) == (0, 3)
    @test word(testbuf("|word word")) == (0, 3)
    @test word(testbuf("|word#@!")) == (0, 3)
    @test word(testbuf("|word !##@")) == (0, 3)

    # @test word(testbuf("word| !##@")) == (4, 4)

end

@testset "a WORD textobject" begin
    @test WORD(testbuf("|word !##@")) == (0, 3)
    @test word(testbuf("|word#@!")) == (0, 6)
end

@testset "space textobject" begin
    @test space(testbuf("|    ")) == (0, 3)
    @test space(testbuf("this|  space")) == (4, 5)
    @test space(testbuf("this | space")) == (4, 5)
    @test space(testbuf("this  |space")) == (6, 6)
end
