
# abstract type Verb end
# struct Move <: Verb end
# struct Yank <: Verb end
# struct Delete <: Verb end
# struct Change <: Verb end
# struct Find <: Verb
#     forward :: Bool
# end
# Find(;forward::Bool=true) = Find(forward)

# struct Action
#     verb :: Verb
#     quantity :: Integer
#     motion :: Motion
# end

# Action(motion :: Motion) = Action(Move(), 1, motion)
# Action(verb :: Verb, motion :: Motion) = Action(verb, 1, motion)

abstract type VimMode end
abstract type VimCommand end

# InsertMode is the standard Julia REPL
struct InsertMode <: VimMode end
struct NormalMode <: VimMode end
# A mode in which the user selects the motion which will
# be used for `Action`
# abstract type AbstractSelectMode{T <: Action} <: VimMode end
# eltype(::AbstractSelectMode{T}) where {T} = T

"""
In this mode a user selects the motion
to apply the Action to. For example, this mode
will be enabled after `d` in the command `diw`
"""
# struct MotionMode{T <: Action} <: AbstractSelectMode{T} end

# const NormalMode = MotionMode{Move}

# """
# A mode which requires the char value
# of the pressed key
# """
# struct FindChar{T <: Action} <: AbstractSelectMode{T} end
# struct ToChar{T <: Action} <: AbstractSelectMode{T} end

# struct SelectRegister <: VimCommand end


