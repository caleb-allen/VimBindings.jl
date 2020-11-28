
abstract type Action end
struct Move <: Action end
struct Yank <: Action end
struct Delete <: Action end
struct Change <: Action end

abstract type VimMode end
abstract type VimCommand end

# InsertMode is the standard Julia REPL
struct InsertMode <: VimMode end
# A mode in which the user selects the motion which will
# be used for `Action`
abstract type AbstractSelectMode{T <: Action} <: VimMode end
eltype(::AbstractSelectMode{T}) where {T} = T

"""
A mode in which the user selects the motion
to apply the Action to. For example, this mode
will be enabled after `d` in the command `diw`
"""
struct MotionMode{T <: Action} <: AbstractSelectMode{T} end

const NormalMode = MotionMode{Move}

"""
A mode which requires the char value
of the pressed key
"""
struct FindChar{T <: Action} <: VimCommand end
struct ToChar{T <: Action} <: VimCommand end
struct SelectRegister <: VimCommand end


mutable struct VimBindingState
    mode :: Union{VimMode, VimCommand}
    registers :: Dict{Char, String}
    register :: Char
end

VimBindingState() = VimBindingState(InsertMode(),
                                    Dict{Char, String}(),
                                    '"')
