using VimBindings.Parse
@testset "pika parse" begin
    @test parse_command("5w") == MotionCommand(5, 'w')
    @test parse_command("10w") == MotionCommand(10, 'w')
end

