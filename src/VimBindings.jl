module VimBindings

using REPL
using REPL.LineEdit

const LE = LineEdit

function init()
  repl = Base.active_repl
  global juliamode = repl.interface.modes[1]
  juliamode.prompt = "julia[i]> "
  juliamode.keymap_dict['`'] = trigger_normal_mode
  #= juliamode.keymap_dict['\e'] = trigger_normal_mode =#

  # remove normal mode if it's already added
  normalindex = 0
  for (i, m) in enumerate(repl.interface.modes)
    if hasproperty(m, :prompt) && m.prompt == "julia[n]> "
      normalindex = i
    end
  end
  if normalindex != 0
    deleteat!(repl.interface.modes, normalindex)
  end

  global normalmode = REPL.Prompt("julia[n]> ")
  
  shellprompt = repl.interface.modes[2]
  # `juliaprompt` here is used to go back to julia mode after the command
  normalmode.on_done = REPL.respond(split, repl, juliamode)
  normalmode.on_enter = juliamode.on_enter

  keymap = Dict{Char,Any}(
              'h' => (s::LineEdit.MIState, o...)->LE.edit_move_left(s),
              'l' => (s::LineEdit.MIState, o...)->LE.edit_move_right(s),
              'e' => (s::LineEdit.MIState, o...)->LE.edit_move_word_right(s),
              'E' => (s::LineEdit.MIState, o...)->edit_move_phrase_right(s),
              'b' => (s::LineEdit.MIState, o...)->LE.edit_move_word_left(s),
              'B' => (s::LineEdit.MIState, o...)->edit_move_phrase_left(s),
              'a' => (s::LineEdit.MIState, o...)->begin
                LE.edit_move_right(s)
                trigger_insert_mode(s, o...)
              end,
              'A' => (s::LineEdit.MIState, o...)->begin
                edit_move_end(s)
                trigger_insert_mode(s, o...)
              end,
              'i' => trigger_insert_mode,
              '$' => (s::LineEdit.MIState, o...)->edit_move_end(s),
              '^' => (s::LineEdit.MIState, o...)->edit_move_start(s),
              'x' => (s::LineEdit.MIState, o...)->LE.edit_delete(s),
           )

  normalmode.keymap_dict = keymap

  push!(repl.interface.modes, normalmode)
  return
end


function edit_move_end(s::LE.MIState)
  buf = LE.buffer(s)
  while !eof(buf)
    LE.char_move_right(buf)
  end
  pos = position(buf)
  seek(buf,pos)
  LE.refresh_line(s)
  return true
end

function edit_move_start(s::LE.MIState)
  buf = LE.buffer(s)
  while position(buf) > 0
    LE.char_move_left(buf)
  end
  pos = position(buf)
  seek(buf,pos)
  LE.refresh_line(s)
  return true
end


is_non_phrase_char(c::Char) = c in """ \t\n"""

function edit_move_phrase_right(s::LE.MIState)
  buf = LE.buffer(s)
  if !eof(buf)
    LE.char_move_word_right(buf, is_non_phrase_char)
    return LE.refresh_line(s)
  end
  return nothing
end

function edit_move_phrase_left(s::LE.MIState)
  buf = LE.buffer(s)
  if position(buf) > 0
    LE.char_move_word_left(buf, is_non_phrase_char)
    return LE.refresh_line(s)
  end
  return nothing
end


function trigger_insert_mode(state::LineEdit.MIState, repl::Any, char::AbstractString)
  iobuffer = LineEdit.buffer(state)
  LineEdit.transition(state, juliamode) do
    prompt_state = LineEdit.state(state, juliamode)
    prompt_state.input_buffer = copy(iobuffer)
  end
end

function trigger_normal_mode(state::LineEdit.MIState, repl::LineEditREPL, char::AbstractString)
  iobuffer = LineEdit.buffer(state)
  LineEdit.transition(state, normalmode) do
    prompt_state = LineEdit.state(state, normalmode)
    prompt_state.input_buffer = copy(iobuffer)
  end
end


function key_press(state::REPL.LineEdit.MIState, repl::LineEditREPL, char::String)
end


function getsocket()
  if !isdefined(Main, :socket)
    global socket = connect(1234)
  end
  return socket
end

function debug_mode(state::REPL.LineEdit.MIState, repl::LineEditREPL, char::String)
  socket = getsocket()
  # iobuffer is not displayed to the user
  iobuffer = LineEdit.buffer(state)

  # write character typed into line buffer
  #= LineEdit.edit_insert(iobuffer, char) =#
  
  # write character typed into repl
  #= LineEdit.edit_insert(state, char) =#
  #
  # move to start of iostream to read what the user
  # has typed
  seekstart(iobuffer)
  line = read(iobuffer, String)
  println(socket, "line: ", line)

  # Show what character user typed
  println(socket, "character: ", char)
end

#= juliamode.keymap_dict['9'] = debug_mode =#


function funcdump(args...)
  socket = getsocket()
  for arg in args
    println(socket, typeof(arg))
    println(socket, propertynames(arg))
  end
end

end
