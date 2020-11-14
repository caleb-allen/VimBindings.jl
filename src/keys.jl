#=
-----------
Normal Mode
-----------
=#

function i(state :: NormalMode)
    trigger_insert_mode(state, repl, char)
end

function d(mode::NormalMode, s::LE.MIState)
    @log VB.mode = MotionMode{Delete}()
end

function c(mode::NormalMode, s::LE.MIState)
    VB.mode = MotionMode{Change}()
end

# example for `f` find command, e.g.
# `dfi`
# function i(state::FindCharState) :: Motion

# end

function w(mode::MotionMode{T} where T, s::LE.MIState)
    buf = LE.buffer(s)
    motion = word(buf)
    execute(mode, buf, motion)
    LE.refresh_line(s)
    vim_reset()
    return true
end

function b(mode::MotionMode{T} where T, s::LE.MIState)
    buf = LE.buffer(s)
    motion = word_back(buf)
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

function execute(::AbstractSelectMode{Change},
                 buf :: IOBuffer,
                 motion::Motion)
    change(buf, motion)
end

function execute(::AbstractSelectMode{Move},
                 buf :: IOBuffer,
                 motion::Motion)
    move(buf, motion)
end
