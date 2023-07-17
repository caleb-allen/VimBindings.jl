using VimBindings.TextUtils
using VimBindings.Changes
import VimBindings.Changes: freeze, BufferRecord, record, reset!, Entry
import VimBindings.PkgTools: run as run_command

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

@testset "iterate change entries" begin
    reset!()
    buf = testbuf("Hello |world!")
    e1 = Entry(freeze(buf))

    truncate(buf, 5)

    e2 = Entry(freeze(buf), e1)
    e1.next[] = e2

    e3 = Entry(freeze(buf), e2)
    e2.next[] = e3

    @test e2.prev[] == e1
    @test e2.next[] == e3
    @test e3.next[] == e3
    @test Changes.is_first(e1) == true
    @test Changes.is_first(e2) == false
    @test Changes.is_first(e3) == false
    @test Changes.is_last(e1) == false
    @test Changes.is_last(e2) == false
    @test Changes.is_last(e3) == true
    @test Changes.root_of(e2) == e1
    @test Changes.root_of(e3) == e1

    (next, state) = iterate(e1)
    @test next == e1
    @test state == e1
    (next, state) = iterate(next, state)
    @test next == e2
    @test state == e2
    (next, state) = iterate(next, state)
    @test next == e3
    @test state == e3

    @test iterate(next, state) === nothing

    count = 0
    for entry in e1
        count += 1
        if count > 5
            error("too many")
        end
    end
    @test count == 3
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
    # @test buf == testbuf("Hello redo!|n|")

    undo!(buf)
    # @test buf == testbuf("Hello |n|")
end

@testset "undo/redo cursor" begin
    reset!()
    buf = testbuf("Hello |")
    # test that `dw` records an entry
    record(buf)
    @test Changes.latest[].record == BufferRecord("Hello ", 6)
    
    run_command("u", buf)
    @test Changes.latest[].record == BufferRecord("", 0)
    # running undo records the record as `next`
    @test Changes.latest[].next[].record == BufferRecord("Hello ", 6)

end

@testset "undo/redo cursor" begin
    reset!()
    buf = testbuf("Hello worl|d")
    record(buf)
    run_command("daw", buf)
    # test that `dw` records an entry
    @test buf == testbuf("Hello |")
    record(buf)
    @test Changes.latest[].record == BufferRecord("Hello ", 6)

    run_command("u", buf)
    @test Changes.latest[].record == BufferRecord("Hello world", 6)
    # running undo records the record as `next`
    @test Changes.latest[].next[].record == BufferRecord("Hello ", 6)

    # \x12 == C-r for redo
    run_command("\x12", buf)
    @test buf == testbuf("Hello |")
    @test Changes.latest[].record == BufferRecord("Hello ", 6)
    @test Changes.latest[].next[].record == BufferRecord("Hello ", 6)
end
