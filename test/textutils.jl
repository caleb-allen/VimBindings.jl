using VimBindings.TextUtils
@testset "VimBuffer" begin
    s = "Sample|n| buffer"
    iobuf = IOBuffer()
    expected = " VimBuffer(\"$s\")"
    show(iobuf, MIME("text/plain"), testbuf(s))

    seek(iobuf, 0)
    printed = read(iobuf, String)
    @test printed == expected


    s = "|n|Sample buffer"
    iobuf = IOBuffer()
    expected = " VimBuffer(\"$s\")"
    show(iobuf, MIME("text/plain"), testbuf(s))
    seek(iobuf, 0)
    printed = read(iobuf, String)
    @test printed == expected

    s = "Sample buffer|n|"
    iobuf = IOBuffer()
    expected = " VimBuffer(\"$s\")"
    show(iobuf, MIME("text/plain"), testbuf(s))
    seek(iobuf, 0)
    printed = read(iobuf, String)
    @test printed == expected


    @test_throws ArgumentError testbuf("")
end


@testset "test buffer with mode" begin

    buf = testbuf("asdf|fdsa")
    @test buf.size == 8
    @test position(buf) == 4

    buf = testbuf("hello worl|d this is a test")
    @test position(buf) == 10

    buf = testbuf("|hello world")
    @test position(buf) == 0
    @test buf.size == 11

    before = "The first line\nThe second| line\nThe third line"
    buf = testbuf(before)
    seek(buf, 0)
    after = read(buf, String)
    # @test before == after
    @test length(after) == length(before) - 1 # -1 to account for | char
end

@testset "chars by cursor" begin
    @test chars_by_cursor(testbuf("ab|cd")) == (WordChar('b'), WordChar('c'))
    @test chars_by_cursor(testbuf("π|a")) == (WordChar('π'), WordChar('a'))
end

@testset "TextChar" begin
    # @test_throws "Invalid character" TextChar('\x80')
end
@testset "junction" begin
    @test junction_type('a', ' ') == Set(Junction[Start{Whitespace}(), End{Object}()])
end

@testset "is word end" begin
    @test is_word_end(testbuf("hello |%^%^%^")) == false
    @test is_word_end(testbuf("hello| %^%^%^")) == true
    @test is_word_end(testbuf("a wor|d%#%#%#")) == false
    @test is_word_end(testbuf("a word|%#%#%#")) == true
    @test is_word_end(testbuf("dasd%#%#%|#")) == false
    @test is_word_end(testbuf("dasd%#%#%#|")) == true
end

@testset "is object start" begin
    @test is_word_start(testbuf("hello| world")) == false
    @test is_word_start(testbuf("hello |world")) == true
    @test is_word_start(testbuf("|hello world")) == true
    @test is_word_start(testbuf("  |hello world")) == true
    @test is_word_start(testbuf("|   hello world")) == false
    @test is_word_start(testbuf("abcde|%%%%%")) == true
    @test is_word_start(testbuf("abcde%%|%%%")) == false
    @test is_word_start(testbuf("abcde|1234%%%%%")) == false
    @test is_word_start(testbuf("|%%% hello world")) == true
end

@testset "is whitespace end" begin
    @test is_whitespace_end(testbuf("hello| world")) == false
    @test is_whitespace_end(testbuf("hello |world")) == true
    @test is_whitespace_end(testbuf("|hello world")) == false
    @test is_whitespace_end(testbuf("  |hello world")) == true
    @test is_whitespace_end(testbuf("  | hello world")) == false
    @test is_whitespace_end(testbuf("|   hello world")) == false
    @test is_whitespace_end(testbuf("hello world| ")) == false
    @test is_whitespace_end(testbuf("hello world |")) == true
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


@testset "is inside word " begin
    @test is_in_word(testbuf("hello|world")) == true
    @test is_in_word(testbuf("hello| world")) == false
    @test is_in_word(testbuf("hello|%%%%")) == false
    @test is_in_word(testbuf("hello%%|%%")) == true
    @test is_in_word(testbuf("|hello%%%%")) == false
end

@testset "is inside object" begin
    @test is_in_object(testbuf("hello|world")) == true
    @test is_in_object(testbuf("hello| world")) == false
    @test is_in_object(testbuf("hello|%%%%")) == true
    @test is_in_object(testbuf("hello%%|%%")) == true
    @test is_in_object(testbuf("|hello%%%%")) == false
end
@testset "is line start " begin
    @test is_line_end(testbuf("|\n")) == true
    @test is_line_end(testbuf("one line\t|\nhello")) == true
    @test is_line_end(testbuf("one line\t\nhello|")) == true
    @test is_line_end(testbuf("one line\t\nhello|\n")) == true
    @test is_line_end(testbuf("|")) == true

    @test is_line_start(testbuf("|")) == true
    @test is_line_start(testbuf("|\n")) == true
    @test is_line_start(testbuf("\n|hello")) == true
    @test is_line_start(testbuf("one line|\nhello")) == false
    @test is_line_start(testbuf("one line \n|hello")) == true

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

@testset "chars by cursor" begin end

@testset "read left/right char in buffer" begin
    @test peek_left(testbuf("π|τ")) == 'π'
    @test peek_right(testbuf("π|τ")) == 'τ'

    @test peek_left(testbuf("|A")) === nothing
    @test peek_right(testbuf("A|")) === nothing

    # test a buffer whose cursor is in an invalid index
    buf = IOBuffer("πτ")
    skip(buf, 1)
    @test peek_left(buf) == 'π'
    @test peek_right(buf) == 'τ'


end
