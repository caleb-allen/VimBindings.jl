# using VimBindings
import VimBindings: word_next, word_end, word_big_next, Motion, is_punctuation, find_c, line_begin
# import VimBindings: line, TextObject
using Test
# const VB = VimBindings

# include("action.jl")
include("parse.jl")
include("textutils.jl")
include("motion.jl")
include("command.jl")
include("textobject.jl")
include("registers.jl")

