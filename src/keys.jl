
function i(state :: NormalMode)
    trigger_insert_mode(state, repl, char)
end

# function d(state::LineEdit.MIState, repl::Any, char::AbstractString)
# end
function d(mode::NormalMode, s::LE.MIState)
    @log global vim_mode = SelectMotion{Delete}()
end

# example for `f` find command, e.g.
# `dfi`
# function i(state::FindCharState) :: Motion

# end

function w(mode::SelectMotion{T} where T, s::LE.MIState)
    buf = LE.buffer(s)
    motion = word(buf)
    # action?
    execute(mode, buf, motion)
    LE.refresh_line(s)
    vim_reset()
    return true
end

function execute(::AbstractSelectMode{Delete},
                 buf :: IOBuffer,
                 motion::Motion)
    delete(buf, motion)
end

