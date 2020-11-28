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

function p(mode::NormalMode, s::LE.MIState)
    buf = LE.buffer(s)
    paste(buf, vim.register)
    LE.refresh_line(s)
end

function d(mode::NormalMode, s::LE.MIState)
    @log vim.mode = MotionMode{Delete}()
end

function c(mode::NormalMode, s::LE.MIState)
    @log vim.mode = MotionMode{Change}()
end

function y(mode::NormalMode, s::LE.MIState)
    @log vim.mode = MotionMode{Yank}()
end


function double_quote(mode::NormalMode, s::LE.MIState)
    @log vim.mode = SelectRegister()
end

function f(mode::MotionMode{T} where T, s::LE.MIState)
    @log t = eltype(mode)
    @log vim.mode = FindChar{t}()
end

function d(mode::MotionMode{Delete}, s)
    buf = buffer(s)
    motion = Motion(line(buf))
    execute(mode, s, motion)
    refresh_line(s)
    vim_reset()
    return true
end

function y(mode::MotionMode{Yank}, s)
    buf = buffer(s)
    motion = Motion(line(buf))
    execute(mode, s, motion)
    vim_reset()
    return true
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
@motion(e, word_end)
@motion(b, word_back)
@motion(caret, (buf -> Motion(position(buf), 0)))
@motion(dollar, line_end)


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

function execute(::AbstractSelectMode{Yank},
                 s :: LE.MIState,
                 motion::Motion)
    yank(s, motion)
end

