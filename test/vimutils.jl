# utilities for running commands and comparing output to vim

using VimBindings.TextUtils
function run_vim_command(content::String, cmd::String)
    buf = IOBuffer(content)
    closewrite(buf)
    p = @show pipeline(buf, `vim - -nEs -c "+normal $cmd" -c "%print" -c "q!"`)    
    output = read(p, String)
    # skip the first line which says "Vim: reading from stdin..."
    result = join(split(output, '\n')[2:end])
    return result
end

function run_vim_command(content::VimBuffer, cmd::String)
    buf = content.buf
    cursor_pos = position(buf)
    seek(buf, 0)
    p = @show pipeline(buf, `vim - -nEs -c "norm $(cursor_pos)l" -c "normal $cmd" -c "%print" -c "q!"`)    
    output = read(p, String)
    # skip the first line which says "Vim: reading from stdin..."
    result = join(split(output, '\n')[2:end])
    return result
  
end