using VimBindings.TextUtils
using VimBindings.Changes

@testset "BufferRecord" begin
    a = BufferRecord(VimBuffer("Hello world|!"))
    b = BufferRecord(VimBuffer("Hello worl|d"))
    c = BufferRecord(VimBuffer("Hello world|!"))
    
    @test a != b
    @test freeze(VimBuffer("Hello world|!")) != BufferRecord(VimBuffer("Hello |!"))
    @test freeze(VimBuffer("Hello world|!")) == BufferRecord(VimBuffer("Hello world|!"))
end