using .Commands


"""
    Execute the given command, and return whether to refresh the displayed line
"""
function execute(s :: LE.MIState, command :: MotionCommand) :: Bool
    log("executing motion command: $(command.motion)")
    for rep in 1:command.r1
        fn_name = get_safe_name(command.motion)
        buf = buffer(s)
        # call the command's function to generate the motion object
        motion = eval(Expr(:call, fn_name, buf))

        # execute the motion object
        motion(s)
        # fn(buf)
    end
    return true
end
