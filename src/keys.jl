#=
-----------
Normal Mode
-----------
=#

function i(mode :: NormalMode, s::LE.MIState)
    trigger_insert_mode(s)
end

function a(mode :: NormalMode, s::LE.MIState)
    buf = LE.buffer(s)
    motion = Motion(position(buf), position(buf) + 1)
    execute(mode, s, motion)
    trigger_insert_mode(s)
    return true
end

function x(mode :: NormalMode, s::LE.MIState)
    buf = LE.buffer(s)
    motion = Motion(position(buf), position(buf) + 1)
    execute(MotionMode{Delete}(), s, motion)
    LE.refresh_line(s)
    return true
end

function d(mode::NormalMode, s::LE.MIState)
    @log VB.mode = MotionMode{Delete}()
end

function c(mode::NormalMode, s::LE.MIState)
    @log VB.mode = MotionMode{Change}()
end

macro motion(k, fn)
    return quote
        function $(esc(k))(mode::MotionMode{T} where T, s::LE.MIState)
            buf = LE.buffer(s)
            motion = $fn(buf)
            execute(mode, s, motion)
            LE.refresh_line(s)
            vim_reset()
            return true
        end
    end
end

@motion(h, (buf) -> Motion(position(buf), position(buf) - 1))
@motion(l, (buf) -> Motion(position(buf), position(buf) + 1))
@motion(w, word)
@motion(b, word_back)


function execute(::AbstractSelectMode{Delete},
                 s :: LE.MIState,
                 motion::Motion)
    delete(s, motion)
end

function execute(::AbstractSelectMode{Change},
                 s :: LE.MIState,
                 motion::Motion)
    change(s, motion)
end

function execute(::AbstractSelectMode{Move},
                 s :: LE.MIState,
                 motion::Motion)
    move(s, motion)
end
