import VimBindings.Motion


@testset "motion addition" begin
    m1 = Motion(0, 4)
    m2 = Motion(4, 8)

    @test m1 + m2 == Motion(0, 8)

    @test Motion(1, 3) + Motion(3, 5) == Motion(1, 5)


    @test Motion(3, 0) + Motion(3, 5) == Motion(0, 5)
end
