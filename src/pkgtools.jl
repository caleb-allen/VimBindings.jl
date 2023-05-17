"""
Tools for running or testing the package. This module is meant for code that is
    not a standard unit test, or is related to other "meta-package" features like
    precompilation or timing.

The end of this file contains precompilation code
"""
module PkgTools
import ..VimBuffer, ..parse_command, ..testbuf, ..execute
const TEST_STRING = """abcdefghijklmnopqrstuvwxyz "' 0987654321 A B C D E F G H| I J K L M N O P Q R S T U V W X Y Z 98 76 54 32 21 !@#%^9^&*() abcdefghijklmnopqrstuvwxyz '" 0987654321"""


function partial_vim_commands_list()::Vector{String}
    s = """
        h j k l
        3h 3j 3k 3l
        w W e E b B ^ \$ 0
        dh daw cw ciw caW caw daW cW ct"
        fa Fa ta Ta a A i I o O x X C S dd D"""
    String.(split(s))
end

"""
Convenience function to return each vim command alongside a pre-constructed
    vim buffer
"""
commands_and_buffers()::Vector{Tuple{String,VimBuffer}} =
    map(partial_vim_commands_list()) do cmd
        (cmd, testbuf(TEST_STRING))
    end

function run(cmd::String, buf::VimBuffer=testbuf(TEST_STRING))
    command = parse_command(cmd)
    execute(buf.buf, command)
end

function time_commands()
    map(commands_and_buffers()) do (cmd, buf)
        @elapsed @eval run($cmd, $buf)        
    end
end

end

using PrecompileTools

# precompilation
@setup_workload begin
    # allocate test buffers beforehand to exclude them from precompilation
    commands = PkgTools.commands_and_buffers()
    @compile_workload begin
        for (cmd, buf) in commands
            PkgTools.run(cmd, buf)
        end
    end
end

