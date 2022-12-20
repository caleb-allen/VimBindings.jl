using VimBindings.TextUtils

@testset "space textobject" begin
    @test space(testbuf("|    ")) == (0, 3)
    @test space(testbuf("this|  space")) == (4, 5)
    @test space(testbuf("this | space")) == (4, 5)
    @test space(testbuf("this  |space")) == (6, 6)
end

@testset "basic movements" begin
    keystack = "a"
    buf = testbuf("|12345")
    mode = "normal"

end

@testset "0: beginning of line" begin

    s_cmd = String(key_stack)


    @test run(testbuf("an exampl|e sentence"), "0") == testbuf("|an example sentence")
end

"""
run a vim command on a buffer of text. Return a buffer of the result of the command
"""
function run(buf, command) :: IOBuffer
    if !well_formed(command)
        error("Command not well formed", command)
    end

    cmd = parse_command(buf)

    # TODO how to recreate "MIState?"
    # Or should the mode logic be altered to avoid using MIState?
    execute(s, cmd)
end

function run(test_string :: String, command)
    buf = testbuf(test_string)
    run(buf, command)
end



@testset "hl with delete" begin
    @test run("asdf|", "h") == testbuf("asd|f")
    @test run("asdf|", "l") == testbuf("")
    @test run("asdf|", "dl") == testbuf("asdf|")
    @test run("asdf|", "dh") == testbuf("asd|")
    @test run("asdf|", "X") == testbuf("asd|")
end

@testset "textobjects" begin
    @test run("", "") == testbuf("")
    
    @test run("as|df", "cw") == testbuf("as|")

    @test run("a as|df b", "cw") == testbuf("a as| b")
    @test run("a as|df b", "cw") == testbuf("a as| b")
    @test run("a as|df b", "ciw") == testbuf("a | b")

end