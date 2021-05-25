using VimBindings.TextUtils
@testset "text object end" begin
    buf = IOBuffer("hello world")

    @test is_object_end(buf) == false

    seek(buf, 4)
    @assert peek(buf, Char) == 'o'

    @test is_object_end(buf) == true

    seek(buf, 5)
    @test is_object_end(buf) == false

    seek(buf, 10)
    @assert peek(buf, Char) == 'd'

    @test is_object_end(buf) == true
end

@testset "is object end" begin
    @test is_object_end(testbuf("hello |%^%^%^")) == false
    @test is_object_end(testbuf("hell|o %^%^%^")) == true
    @test is_object_end(testbuf("a wor|d%#%#%#")) == true
    @test is_object_end(testbuf("a word|%#%#%#")) == false
    @test is_object_end(testbuf("dasd%#%#%|#")) == true
    @test is_object_end(testbuf("dasd%#%#%#|")) == false
end

@testset "is object start" begin
    @test is_object_start(testbuf("hello| world")) == false
    @test is_object_start(testbuf("hello |world")) == true
    @test is_object_start(testbuf("|hello world")) == true
    @test is_object_start(testbuf("  |hello world")) == true
    @test is_object_start(testbuf("|   hello world")) == false
    @test is_object_start(testbuf("abcde|%%%%%")) == true
    @test is_object_start(testbuf("abcde%%|%%%")) == false
    @test is_object_start(testbuf("abcde|1234%%%%%")) == false
    @test is_object_start(testbuf("|%%% hello world")) == true
end

@testset "is whitespace end" begin
    @test is_whitespace_end(testbuf("hello| world")) == true
    @test is_whitespace_end(testbuf("hello |world")) == false
    @test is_whitespace_end(testbuf("|hello world")) == false
    @test is_whitespace_end(testbuf("  |hello world")) == false
    @test is_whitespace_end(testbuf("  | hello world")) == true
    @test is_whitespace_end(testbuf("|   hello world")) == false
    @test is_whitespace_end(testbuf("hello world| ")) == true
    @test is_whitespace_end(testbuf("hello world |")) == false
    @test is_whitespace_end(testbuf("hello |   world")) == false
    @test is_whitespace_end(testbuf("hello worl|d")) == false
end

@testset "is whitespace start" begin
    @test is_whitespace_start(testbuf("hello| world")) == true
    @test is_whitespace_start(testbuf("hello |world")) == false
    @test is_whitespace_start(testbuf("|hello world")) == false
    @test is_whitespace_start(testbuf("  |hello world")) == false
    @test is_whitespace_start(testbuf("  | hello world")) == false
    @test is_whitespace_start(testbuf("|   hello world")) == true
    @test is_whitespace_start(testbuf("hello world| ")) == true
    @test is_whitespace_start(testbuf("hello world |")) == false
    @test is_whitespace_start(testbuf("hello |   world")) == false
    @test is_whitespace_start(testbuf("hello|   world")) == true
    @test is_whitespace_start(testbuf("hello|%%%%world")) == false
end


@testset "test buffer" begin
    buf = testbuf("asdf|fdsa")
    @test buf.size == 8
    @test position(buf) == 4

    buf = testbuf("hello worl|d this is a test")
    @test position(buf) == 10

    buf = testbuf("|hello world")
    @test position(buf) == 0
    @test buf.size == 11
end
