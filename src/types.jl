
abstract type Action end
struct Move <: Action end
struct Delete <: Action end
struct Change <: Action end

abstract type VimMode end
# InsertMode is the standard Julia REPL
struct InsertMode <: VimMode end

# A mode in which the user selects the motion which will
# be used for `Action`
abstract type AbstractSelectMode{T <: Action} <: VimMode end

eltype(::AbstractSelectMode{T}) where {T} = T
# eltype(x) = eltype(typeof(x))

# findparam(ex::AbstractSelectMode{T}) where {T} = T

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
abstract type SelectCharMode{T <: Action} <: AbstractSelectMode{T} end
# struct SelectRegister{T <: Action} <: SelectCharMode{T} end
struct FindCharMode{T <: Action} <: SelectCharMode{T} end
struct ToCharMode{T <: Action} <: SelectCharMode{T} end

mutable struct VimBindingState
    mode :: VimMode
end

