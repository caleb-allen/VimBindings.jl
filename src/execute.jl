using .Commands
using .TextObjects
using Match

"""
    Execute the given command, and return whether to refresh the displayed line
"""
function execute(s :: LE.MIState, command :: MotionCommand) :: Bool
    log("executing motion command: $(command.motion)")
    buf = buffer(s)
    for iteration in 1:command.r1
        # fn_name = get_safe_name(command.motion)
        # buf = buffer(s)
        # call the command's function to generate the motion object
        # motion = eval(Expr(:call, fn_name, buf))
        motion = gen_motion(buf, command.motion)
        if is_stationary(motion)
            @match key(command) begin
                'j' => history_next(s, mode(s).hist)
                'k' => history_prev(s, mode(s).hist)
            end
        end
        # execute the motion object
        motion(s)
    end
    return true
end

"""
    Generate a Motion object for the given `name`
"""
function gen_motion(buf, name :: Char) :: Motion
    motions = Motion[]
    fn_name = get_safe_name(name)
    # call the command's function to generate the motion object
    motion = eval(Expr(:call, fn_name, buf))
    return motion
end

#=
Generate motion for the given `name` which is a TextObject
=#
function gen_motion(buf, name :: String) :: Motion

end

function execute(s :: LE.MIState, command :: LineOperatorCommand) :: Bool
    for r in 1:command.r1
        buf = buffer(s)
        line_textobject = line(buf)
        line_motion = Motion(line_textobject)
        op_fn = operator_fn(command.operator)
        eval(Expr(:call, op_fn, buf, line_motion))
    end
    return true
end

function execute(s :: LE.MIState, command :: InsertCommand) :: Bool
    # cmds = [aAiIoO]
    buf = buffer(s)
    motion = @match command.c begin
        'a' => a(buf)
        'A' => a_big(buf)
        'i' => nothing
        'I' => line_begin(buf)
        'o' => begin
            endd = line_end(buf).stop
            insert(buf, line_end(buf).stop, '\n')
            if position(buf) == endd
                nothing
            else
                down(buf)
            end
        end
        'O' => begin
            insert(buf, line_zero(buf).stop, '\n')
            up(buf)
        end
    end
    if motion isa Motion
        motion(buf)
    end
    trigger_insert_mode(s)
    return true
end

function execute(s :: LE.MIState, command :: OperatorCommand) :: Bool
    # *5*d2w
    log(command)
    @log op_fn = operator_fn(command.operator)
    for r1 in 1:command.r1
        # 5d*2*w
        for r2 in 1:command.r2
            @log r2
            buf = buffer(s)
            motion = gen_motion(buf, command.action)
            @log result = eval(Expr(:call, op_fn, buf, motion))
        end
    end
    if op_fn === :change
        trigger_insert_mode(s)
    end
    true
end
