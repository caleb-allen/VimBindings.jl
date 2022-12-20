using .Commands
using .TextObjects
using Match


"""
    Execute the given command, and return whether to refresh the displayed line
"""
function execute(buf, command :: MotionCommand) :: Union{VimMode, Nothing}
    log("executing motion command: $(command.motion)")
    # buf = buffer(s)
    for iteration in 1:command.r1
        # call the command's function to generate the motion object
        motion = gen_motion(buf, command.motion)
        if is_stationary(motion)
            # @match key(command) begin
            #     'j' => history_next(s, mode(s).hist)
            #     'k' => history_prev(s, mode(s).hist)
            # end
        end
        # execute the motion object
        motion(buf)
    end
    return nothing
end
function execute(buf, command :: LineOperatorCommand) :: Union{VimMode, Nothing}
    for r in 1:command.r1
        # buf = buffer(s)
        line_textobject = line(buf)
        line_motion = Motion(line_textobject...)
        op_fn = operator_fn(command.operator)
        op_fn(buf, line_motion)
    end
    return nothing
end

function execute(buf, command :: InsertCommand) :: Union{VimMode, Nothing}
    # cmds = [aAiIoO]
    # buf = buffer(s)
    motion = @match command.c begin
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
        'i' => Motion(buf)
        'I' => line_begin(buf)
        'a' => begin
            if !eof(buf)
                Motion(position(buf), position(buf) + 1)
            else
                Motion(buf)
            end
        end
        'A' => begin
            motion = line_end(buf)
            if !eof(buf)
                Motion(motion.start, motion.stop + 1)
            else
                motion
            end
        end
        _ => gen_motion(buf, command.c)
    end
    if motion isa Motion
        motion(buf)
    end
    return insert_mode
end

function execute(buf, command :: OperatorCommand) :: Union{VimMode, Nothing}
    # *5*d2w
    log(command)
    @log op_fn = operator_fn(command.operator)
    for r1 in 1:command.r1
        # 5d*2*w
        for r2 in 1:command.r2
            @log r2
            motion = gen_motion(buf, command.action)
            @log result = eval(Expr(:call, op_fn, buf, motion))
        end
    end
    if op_fn == change
        return insert_mode
    end
    return nothing
end

function execute(buf, command :: SynonymCommand) :: Union{VimMode, Nothing}

    synonyms = Dict(
        'x' => "dl",
        'X' => "dh"
    )
    new_command = parse_command("$(command.r1)$(synonyms[command.operator])")
    
    return execute(buf, new_command)
end
