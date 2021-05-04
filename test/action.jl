import VimBindings: yank, cut

@testset "yanking" begin
    buf = IOBuffer("0123456789")

    @test cut(buf, Motion(0, 3)) == "012"
    @test yank(buf, Motion(0, 3)) == "012"
    @test VB.vim.registers['"'] == "012"

    VB.vim.register = 'a'
    yank(buf, Motion(3, 6))
    @test VB.vim.registers['a'] == "345"

    VB.vim.register = '_'
    @test yank(buf, Motion(3, 6)) === nothing


end
