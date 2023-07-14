include("vimutils.jl")

using VimBindings.TextUtils
using VimBindings.PkgTools
import VimBindings.PkgTools: run, some_vim_commands, TEST_STRING

@test "compare VimBindings.jl and vim" begin
    for cmd in PkgTools.some_vim_commands()
        @test run(TEST_STRING, cmd) == run_vim_command(TEST_STRING, cmd)
    end
end