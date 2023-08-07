import VimBindings: word_next, word_end, word_big_next, Motion, is_punctuation, find_c, line_begin
using Test
using VimBindings.PkgTools

include("nvim.jl")
include("changes.jl")
include("parse.jl")
include("textutils.jl")
include("motion.jl")
include("command.jl")
include("textobject.jl")
include("registers.jl")


@testset "precompilation" begin
    # run the precompilation flow to catch any exceptions
    for (cmd, buf) in PkgTools.commands_and_buffers()
        @test well_formed(cmd) == true
        @test partial_well_formed(cmd) == true
        # === isn't important, just need something to evaluate with @test which will give useful error
        # messages
        @test PkgTools.run(cmd, buf) === buf 
    end
    
    PkgTools.run_junctions()
    PkgTools.changes()
end
