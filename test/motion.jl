import VimBindings.Motion


@testset "motion addition" begin
    m1 = Motion(0, 4)
    m2 = Motion(4, 8)

    @test m1 + m2 == Motion(0, 8)

end
