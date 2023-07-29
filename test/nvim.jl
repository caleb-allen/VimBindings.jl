import VimBindings: VimBuffer
@testset "nvim" begin

end

@testset "cursor position" begin
    buf = testbuf("12345|6789")
    @test Nvim.location(buf) == (1, 5)
    buf = testbuf("""12345
12345
12|345
""")
    @test Nvim.location(buf) == (3, 2)
    
    buf = testbuf("""12345
12345
12|345
""")
    after = testbuf("""|12345
12345
12345
""")

    Nvim.location!(buf, 1, 0)
    @test buf == after
end


