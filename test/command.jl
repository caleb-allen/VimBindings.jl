using VimBindings.TextUtils
using VimBindings.Parse
using VimBindings.Execution
"""
run a vim command on a buffer of text. Return a buffer of the result of the command
"""
function run(buf :: VimBuffer, cmd :: String) :: VimBuffer
    if !well_formed(cmd)
        error("Command not well formed", command)
    end

    command = parse_command(cmd)
    new_mode = execute(buf, command)
    return VimBuffer(buf.buf, VimMode(new_mode))
end

function run(test_string :: String, command) :: VimBuffer
    buf = testbuf(test_string)
    return run(buf, command)
end


@testset "basic movements" begin
    @test run("asdf|", "h") == testbuf("asd|f")
    @test run("asdf|", "l") == testbuf("asdf|")
    @test run("asd|f", "l") == testbuf("asdf|")

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

@testset "c[fFtT]x" begin
    # TODO
    # @test run("|aaaa bbbb ccc ddd", "cfd") == testbuf("aaaa bbbb ccc |i|ddd")
    # @test run("aaaa bbbb |ccc ddd", "cFb") == testbuf("aaaa bbb|i|b ccc ddd")
    # @test run("aaaa bbbb |ccc ddd", "cTb") == testbuf("aaaa bbbb|i| ccc ddd")
    # @test run("aaaa bbbb |ccc ddd", "ctd") == testbuf("aaaa bbbb ccc|i| ddd")
    # 
end

@testset "line operators" begin
    @test run("aaaa bbbb |n|ccc ddd", "C") == testbuf("aaaa bbbb |i|")
    @test run("aaaa bbbb |n|ccc ddd", "cc") == testbuf("|i|")
    @test run("aaaa bbbb |n|ccc ddd", "S") == testbuf("|i|")
end
