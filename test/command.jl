using VimBindings.TextUtils
using VimBindings.Parse
using VimBindings.Execution
"""
run a vim command on a buffer of text. Return a buffer of the result of the command
"""
function run(buf::VimBuffer, cmd::String)::VimBuffer
    if !well_formed(cmd)
        error("Command not well formed: $cmd")
    end

    command = parse_command(cmd)
    new_mode = execute(buf.buf, command)
    return VimBuffer(buf.buf, VimMode(new_mode))
end

function run(test_string::String, command)::VimBuffer
    buf = testbuf(test_string)
    return run(buf, command)
end

# https://github.com/caleb-allen/VimBindings.jl/issues?q=is%3Aissue+is%3Aopen+label%3Abug
@testset "bugs from github" begin
    # https://github.com/caleb-allen/VimBindings.jl/issues/48
    @test run("b::|Float64", "ciw") == testbuf("b::|i|")

    # https://github.com/caleb-allen/VimBindings.jl/issues/46
    @test run("|Hello world", "cw") == testbuf("|i| world")
    @test run("|Hello world", "dw") == testbuf("|world")
    
    # https://github.com/caleb-allen/VimBindings.jl/issues/61
    @test run("Hello world|", "A") == testbuf("Hello world|i|")
    
    # https://github.com/caleb-allen/VimBindings.jl/issues/60
    @test run("println(|)", "o") == testbuf("println()\n|i|")
    # https://github.com/caleb-allen/VimBindings.jl/issues/57
    @test run("|A", "C") == testbuf("|i|")
end


@testset "basic movements" begin
    @test run("asdf|", "h") == testbuf("asd|f")
    @test run("asdf|", "l") == testbuf("asdf|")
    @test run("asd|f", "l") == testbuf("asdf|")
    @test run("a|sdf", "\$") == testbuf("asd|f")
    @test run("asd|f", "\$") == testbuf("asd|f")

end

@testset "0: beginning of line" begin

    @test run("an exampl|e sentence", "0") == testbuf("|an example sentence")
end


@testset "hl with delete" begin
    @test run("asdf|", "h") == testbuf("asd|f")
    @test run("asdf|", "l") == testbuf("asdf|")
    @test run("asdf|", "dh") == testbuf("asd|")
    @test run("asdf|", "dl") == testbuf("asdf|")
    @test run("|asdf", "dl") == testbuf("|sdf")
    @test run("asdf|", "X") == testbuf("asd|")
end

@testset "de" begin
    @test run("a|sdf", "de") == testbuf("a|")
    @test run("a|sdf abcd", "de") == testbuf("a| abcd")
end

@testset "dw" begin
    @test run("a|", "dw") == testbuf("a|")
    @test run("a|sdf abcd", "dw") == testbuf("a|abcd")
end
@testset "distinct behavior of dw and cw" begin
    @test run("fi|rst second third", "cw") == testbuf("fi|i| second third")
    @test run("fi|rst%%%% second third", "cw") == testbuf("fi|i|%%%% second third")
    @test run("fi|rst%%%% second third", "dw") == testbuf("fi|n|%%%% second third")
    @test run("fi|rst%%%% second third", "cW") == testbuf("fi|i| second third")
    @test run("fi|rst%%%% second third", "dW") == testbuf("fi|n|second third")
    @test run("fi|rst second third", "dw") == testbuf("fi|n|second third")
end

@testset "delete / change text objects" begin
    @test run("as|n|df", "cw") == testbuf("as|i|")
    @test run("a as|n|df b", "cw") == testbuf("a as|i| b")
    @test run("a as|n|df b", "ciw") == testbuf("a |i| b")
    @test run("a |asdf b", "ciw") == testbuf("a |i| b")
    @test run("a %%%|asdf b", "ciw") == testbuf("a %%%|i| b")
    @test run("a |asdf b", "ciw") == testbuf("a |i| b")

end

@testset "fFtT" begin
    @test run("|aaaa bbbb ccc ddd", "fd") == testbuf("aaaa bbbb ccc |ddd")
    @test run("aaaa bbbb |ccc ddd", "Fa") == testbuf("aaa|a bbbb ccc ddd")
    @test run("aaaa bbbb |ccc ddd", "Ta") == testbuf("aaaa| bbbb ccc ddd")
    @test run("aaaa bbbb |ccc ddd", "td") == testbuf("aaaa bbbb ccc| ddd")
    @test run("aaaa bbbb |ccc .ddd", "t.") == testbuf("aaaa bbbb ccc| .ddd")
end

@testset "d[fFtT]x" begin
    @test run("|aaaa bbbb ccc ddd", "dfd") == testbuf("|dd")
    @test run("aaaa bbbb |ccc ddd", "dFb") == testbuf("aaaa bbb|ccc ddd")
    @test run("aaaa bbbb |ccc ddd", "dTb") == testbuf("aaaa bbbb|ccc ddd")
    @test run("aaaa bbbb |ccc ddd", "dtd") == testbuf("aaaa bbbb |ddd")
    @test run("aaaa bbbb |ccc .ddd", "dt.") == testbuf("aaaa bbbb |.ddd")
end

@testset "D" begin
    @test run("aaaa bbbb |ccc ddd", "d\$") == testbuf("aaaa bbbb |")
    @test run("aaaa bbbb |ccc ddd", "D") == testbuf("aaaa bbbb |")
    @test run("aaaa bbbb |ccc ddd", "D") == run("aaaa bbbb |ccc ddd", "d\$")
end

@testset "c[fFtT]x" begin
    @test run("|aaaa bbbb ccc ddd", "cfd") == testbuf("|i|dd")
    @test run("aaaa bbbb |ccc ddd", "cFb") == testbuf("aaaa bbb|i|ccc ddd")
    @test run("aaaa bbbb |ccc ddd", "cTb") == testbuf("aaaa bbbb|i|ccc ddd")
    @test run("aaaa bbbb |ccc ddd", "ctd") == testbuf("aaaa bbbb |i|ddd")
    # 
end

@testset "line operators" begin
    @test run("aaaa bbbb |n|ccc ddd", "C") == testbuf("aaaa bbbb |i|")
    @test run("|n|a", "C") == testbuf("|i|")
    @test run("aaaa bbbb |ccc dd", "cc") == testbuf("|i|")
    @test run("aaaa bbbb |ccc dd", "S") == testbuf("|i|")
end

@testset "o and O" begin
    @test run("function |hello()", "o") == testbuf("function hello()\n|i|")
    @test run("function |hello()", "O") == testbuf("|i|\nfunction hello()")
end

@testset "unicode" begin
    s = "\u2200 x \u2203 y"
    s = "∀ x ∃ y"
    @test_broken run("|∀ x ∃ y", "w") == testbuf("∀ |x ∃ y")
    @test_broken run("∀ x |∃ y", "w") == testbuf("∀ x |∃ y")
end

@testset "replace character" begin
    @test run("abcd|e 12345", "rx") == testbuf("abcd|x 12345")
    @test run("|abcde", "3rx") == testbuf("xx|xde")
    @test_broken run("∀ x |∃ y", "rx") == testbuf("∀ x |x y")
end

