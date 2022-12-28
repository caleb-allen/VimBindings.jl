using VimBindings.Motions


@testset "motion addition" begin
    m1 = Motion(0, 4)
    m2 = Motion(4, 8)

    @test m1 + m2 == Motion(0, 8)

    @test Motion(1, 3) + Motion(3, 5) == Motion(1, 5)


    @test Motion(3, 0) + Motion(3, 5) == Motion(0, 5)
end
@testset "motion.jl" begin
    #               0123456789
    #               |-----|
    buf = IOBuffer("Hello worl")
    motion = word_next(buf)
    @test motion == Motion(0, 6)

    @assert is_punctuation('-')
    buf = IOBuffer("Hello-worl")
    motion = word_next(buf)
    @test motion == Motion(0, 5)

    buf = VimBuffer("hell|o world!")
    motion = word_next(buf)
    motion(buf)
    @test buf == VimBuffer("hello |world!")
end

@testset "word end" begin

    buf = IOBuffer("using VimBindings")
    @test word_end(buf) == Motion(0, 4)

    motion = word_end(IOBuffer("VimBindings.jl"))
    @test motion == Motion(0, 10)

    motion = word_end(IOBuffer(" VimBindings.jl"))
    @test motion == Motion(0, 11)
end

@testset "big word" begin
    buf = IOBuffer("push!(LOAD_PATH, dirname(file))")
    motion = word_big_next(buf)
    @test motion == Motion(0, 17)
end

# @testset "begin big word" begin
#     buf = IOBuffer("push!(LOAD_PATH, dirname(file))")
#     seek(buf, 20)
#     @test motion == Motion(0, 17)
# end


@testset "find char" begin

    buf = IOBuffer("using VimBindings")
    @test find_c(buf, 'g') == Motion(0, 4)
end

