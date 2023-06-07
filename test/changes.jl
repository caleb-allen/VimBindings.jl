using VimBindings.TextUtils
using VimBindings.Changes
import VimBindings.Changes: freeze, BufferRecord, record, reset!

@testset "BufferRecord and freeze" begin
    reset!()
    a = freeze(VimBuffer("Hello world|!"))
    b = freeze(VimBuffer("Hello worl|d"))
    
    @test a != b
    @test freeze(VimBuffer("Hello world|!")) != BufferRecord("Hello |!", 1)
    @test freeze(VimBuffer("Hello world|!")) == BufferRecord("Hello world!", 11)
    @test freeze(VimBuffer("Hello|i| world!")) == BufferRecord("Hello world!", 5)
    
    # The record includes the cursor location but does not include it in equality
    @test BufferRecord("Hello world!", 7) == BufferRecord("Hello world!", 5)
end

@testset "record" begin
    reset!()
    buf = testbuf("Hello |world!")
    before = freeze(buf)

    record(buf)
    truncate(buf, 5)
    @assert buf == testbuf("Hello|")
    after = freeze(buf)
    record(buf)
    
    @test Changes.latest[].record == after
    @test Changes.latest[].prev[].record == before
end

@testset "undo / record" begin
    reset!()
    buf = testbuf("Hello |world!")
    before = freeze(buf)
    record(buf)

    truncate(buf, 5)
    @assert buf == testbuf("Hello|")
    after = freeze(buf)
    record(buf)
    
    @test Changes.latest[].record == after
    @test Changes.latest[].prev[].record == before
    
    undo!(buf)
    @test Changes.latest[].record == before
    @test Changes.latest[].next[].record == after

end

@testset "undo" begin
    reset!()
    buf = testbuf("Hello |world!")
    record(buf)
    truncate(buf, 6)
    @test buf == testbuf("Hello |n|")
    record(buf)
    
    undo!(buf)
    @test buf == testbuf("Hello |world!")
end

@testset "redo" begin
    reset!()
    buf = testbuf("Hello |world!")
    record(buf)
    truncate(buf, 6)
    @test buf == testbuf("Hello |n|")
    record(buf)
    
    undo!(buf)
    @test buf == testbuf("Hello |world!")
    
    redo!(buf)
    @test buf == testbuf("Hello |n|")
    undo!(buf)
    @test buf == testbuf("Hello |world!")

    redo!(buf)
    @test buf == testbuf("Hello |n|")
    
    write(buf, "redo!")
    @test buf == testbuf("Hello redo!|n|")
    
    undo!(buf)
    @test buf == testbuf("Hello |n|")
end
