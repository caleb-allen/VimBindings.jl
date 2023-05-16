module Execution
using ..Commands
using ..TextObjects
using ..Util
using ..TextUtils
using ..Motions
using ..Parse
using ..Operators

using Match
import REPL: LineEdit as LE

export execute, ReplAction, history_up, history_down

@enum ReplAction begin
    history_up
    history_down
end

"""
    Execute the given command, and return
"""
function execute(buf, command :: MotionCommand) :: Union{VimMode, ReplAction, Nothing}
    log("executing motion command: $(command.name)")
    # buf = buffer(s)
    repl_action = nothing
    for iteration in 1:command.r1
        # call the command's function to generate the motion object
        @log motion = gen_motion(buf, command)
        if is_stationary(motion)
            @log repl_action = @match key(command) begin
                'j' => history_down
                'k' => history_up
            end
        else
            # execute the motion object
            motion(buf)
        end
    end
    return repl_action
end
function execute(buf, command :: LineOperatorCommand) :: Union{VimMode, Nothing}
    local op_fn = nothing
    for r in 1:command.r1
        # buf = buffer(s)
        line_textobject = line(buf)
        line_motion = Motion(line_textobject...)
        op_fn = operator_fn(command.operator)
        op_fn(buf, line_motion)
    end
    if op_fn == change
        return insert_mode
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
                right(buf)
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
        _ => gen_motion(buf, command)
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
    # From neovim help ":h cw"
    # Special case: When the cursor is in a word, "cw" and "cW" do not include the
    # white space after a word, they only change up to the end of the word.  This is
    # because Vim interprets "cw" as change-word, and a word does not include the
    # following white space.
    # see vim help :h cw regarding this exception
    if command.operator == 'c' && command.action.name in ['w', 'W']
        # in the middle of a word
        if at_junction_type(buf, In{>:Word})
            new_name = if command.action.name == 'w' 'e' else 'E' end
            log("altering 'c$(command.action)' command to 'c$new_name'")
            command = OperatorCommand(command.r1, command.operator, command.action.r1, new_name)
        end
    end
    for r1 in 1:command.r1
        # TODO the iteration on `action.r1` should probably happen in `gen_motion`
        for r2 in 1:command.action.r1
            @log r2
            @log motion = gen_motion(buf, command.action)
            # @log result = eval(Expr(:call, op_fn, buf, motion))
            @log result = op_fn(buf, motion)
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
        'X' => "dh",
        'C' => "c\$",
        'D' => "d\$",
        'S' => "cc"
    )
    new_command = parse_command("$(command.r1)$(synonyms[command.operator])")
    
    return execute(buf, new_command)
end

function execute(buf, command :: ReplaceCommand) :: Union{VimMode, Nothing}
    inserted = 0
    for r1 in 1:command.r1
        delete(buf, right(buf))        
        inserted += LE.edit_insert(buf, command.replacement)
    end
    if inserted > 0
        LE.edit_move_left(buf)
    end
    return nothing
end

end