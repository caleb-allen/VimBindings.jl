module Nvim

import REPL
import REPL.LineEdit as LE
using Neovim
import Neovim: feedkeys, set_client_info, get_buffers, get_current_line, set_line, get_buffer
import Neovim: get_mode, get_line, get_current_buf
import Neovim: read_loop
using Match, MsgPack


function start(addr=nothing)
    global nvim = if addr !== nothing
        nvim_connect(addr, ReplBindingsHandler())
    else
        nvim_spawn()
    end

    nbuffer = Neovim.get_current_buf(nvim)
    attached = Neovim.buf_attach(nbuffer, true, Dict())
    if !attached
        @warn "Neovim did not attach!"
    else
        @info "Neovim attached."
    end

    # atexit() do
    # close connection...
    # end

    # open a vim instance, run `echo serverstart('nvim.sock')`
    # set_client_info(
    #     nvim,
    #     "VimBindings.jl",
    #     Dict("major" => 0,
    #         "minor" => 0,
    #         "patch" => 1
    #     ),
    #     "embedder",
    #     Dict(),
    #     Dict("website" => "https://github.com/caleb-allen/VimBindings.jl/")
    # )



end
function nvim_instance(in::Channel{Char}, addr=nothing)
    nvim = if addr !== nothing
        nvim_connect(addr, nvim_handler)
    else
        nvim_spawn()
    end

    # open a vim instance, run `echo serverstart('nvim.sock')`
    set_client_info(
        nvim,
        "VimBindings.jl",
        Dict("major" => 0,
            "minor" => 0,
            "patch" => 1
        ),
        "embedder",
        Dict(),
        Dict("website" => "https://github.com/caleb-allen/VimBindings.jl/")
    )

    # Nvim.buf_attach(nvim, nbuffer, false, Dict())


    # create_buf(nvim, true, true)

end

abstract type NvimEvent end

struct ReplBindingsHandler
    c::Channel{NvimEvent}
end
ReplBindingsHandler() = ReplBindingsHandler(Channel{NvimEvent}())
struct NvimBufLinesEvent <: NvimEvent
    name::String
    buf
    changedtick::Int
    firstline::Int
    lastline::Int
    linedata::Vector
    more::Bool
end

struct NvimTickChangedEvent <: NvimEvent
    name::String
    buf
    tickchanged 
end

function Neovim.on_notify(handler::ReplBindingsHandler, c, name, args)
    event = if name == "nvim_buf_lines_event"
        NvimBufLinesEvent(name, args...)
    elseif name == "nvim_buf_changedtick_event"
        NvimTickChangedEvent(name, args...)
    end
    @info "notify event" event

    return
    # mode = get_mode(c)["mode"]

    # @debug "mode" mode
    # if there were text changes during normal mode,
    # it was a vim command
    if name == "nvim_buf_lines_event" && mode == "n"
        # TODO get the line data from `args`
        # sync_nvim_to_repl(handler.state, data)
    end
    # @info "" name, args
end

function (handler::ReplBindingsHandler)(event::NvimBufLinesEvent)
    
end

function Neovim.on_request(::ReplBindingsHandler, c, serial, name, args)
    @info "on_request" c serial name args
    reply_error(c, serial, "Client cannot handle request, please override `on_request`")
end

struct NvimState
    mode_start::String
    mode_end::String
    cursor_row::Int
    cursor_col::Int
end

function nvim_strike_key(c, s::LE.MIState)
    # feedkeys(nvim, key)
    mode_start = get_mode(nvim)["mode"] # may be blocking

    feedkeys(nvim, c, "t", true)

    mode_end = get_mode(nvim)["mode"] # may be blocking
    win = Neovim.get_current_window(nvim)
    cur_row, cur_col = Int.(Neovim.get_cursor(win))
    nbuf = Nvim.get_current_buf(nvim)
    lines = Neovim.get_lines(nbuf, 0, -1, false)
    
    buf = LE.buffer(s)
    location!(buf, cur_row, cur_col)
    # @info "nvim strike key" cur_row cur_col mode_start mode_end
    # @info "split_lines" split_lines

    # win = get_current_win(nvim)
    # row, column = win_get_cursor(nvim, win)

    # buf = buffer(s)
    # @match mode_end begin

    #     "row" => begin
    #         if mode_start != "row"
    #             trigger_insert_mode(s)
    #         end
    #     end
    #     "n" => begin
    #         if column != position(buf)
    #             seek(buf, column)
    #         end
    #     end
    #     _ => nothing
    # end

end

function setup_normal_mode(s::LE.MIState)
    buf = LE.buffer(s)
    lines = split_lines(buf)
    row, col = location(buf)
    @info "Set up nvim nornmal mode" lines row col

    nbuf = Nvim.get_current_buf(nvim)
    Neovim.set_lines(nbuf, 0, 10, false, String[])
    Neovim.set_lines(nbuf, 0, 0, false, String.(lines))
    
    win = Neovim.get_current_window(nvim)
    Neovim.set_cursor(win, (row, col))
    
end

location(s::LE.MIState) = location(LE.buffer(s))
"""
Get the location of the buffer in (row, column) coordinates
"""
function location(buf::IO)::Tuple{Integer, Integer}
    pos = position(buf)
    lines = String.(split_lines(buf))
    row = 1
    col = 1
    while pos > textwidth(lines[row]) && row < length(ls)
        pos -= textwidth(lines[row])
        row += 1
    end
    col = pos
    (row, col)
end

function location!(buf::IO, row, col)
    start = position(buf)
    chars = 0
    seekstart(buf)
    
    buf_rows = 1
    while buf_rows < row
        eof(buf) && break
        c = read(buf, Char)
        if c == '\n'
            buf_rows += 1
        end
    end

    for i in 1:col
        eof(buf) && break
        read(buf, Char) 
    end
end

function split_lines(buf::IO)
    content = String(take!(copy(buf)))
    split_lines = split(content, '\n')
    return split_lines

    seek(buf, 0)
    s = read(buf, String)
    # split_lines = @p begin
    #     split(s, '\n')
    #     map(String(_))
    # end
    return split_lines
    split_lines = tuple(split_lines...)
    # Neovim.put(nvim, split_lines, "l", true, true)
    nvim_buffer = Neovim.get_current_buf(nvim)
    Neovim.set_lines(nvim_buffer, 0, -1, false, split_lines)
end

function sync_nvim_to_repl(s::LE.MIState, data)
    # TODO fetch split_lines f
end

end
