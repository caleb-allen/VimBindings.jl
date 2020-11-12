
function i(state::LineEdit.MIState, repl::Any, char::AbstractString)
    trigger_insert_mode(state, repl, char)
end
