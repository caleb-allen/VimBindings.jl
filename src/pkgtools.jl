"""
Tools for running or testing the package. This module is meant for code that is
    not a standard unit test, or is related to other "meta-package" features like
    precompilation or timing.

The end of this file contains precompilation code
"""
module PkgTools
import ..VimBuffer, ..parse_command, ..testbuf, ..execute, ..well_formed, ..partial_well_formed
import ..Changes: record, undo!, redo!, freeze, thaw!, reset!
import ..TextUtils: junction_type, TextChar, is_word_start, is_whitespace_start,
    is_object_start, is_word_end, is_object_end, is_whitespace_end
using Combinatorics

const TEST_STRING = """abcdefghijklmnopqrstuvwxyz "' 0987654321 A B C D E F G H| I J K L M N O P Q R S T U V W X Y Z 98 76 54 32 21 !@#%^9^&*() abcdefghijklmnopqrstuvwxyz '" 0987654321"""


function some_vim_commands()::Vector{String}
    s = """
        h j k l
        3h 3j 3k 3l
        w W e E b B ^ \$ 0
        dh daw cw ciw caW caw daW cW ct"
        fa Fa ta Ta a A i I o O x X C S dd D
        u \x12
        """
    String.(split(s))
end

"""
Convenience function to return each vim command alongside a pre-constructed
    vim buffer
"""
commands_and_buffers()::Vector{Tuple{String,VimBuffer}} =
    map(some_vim_commands()) do cmd
        (cmd, testbuf(TEST_STRING))
    end

function run(cmd::String, buf::VimBuffer=testbuf(TEST_STRING))
    command = parse_command(cmd)
    execute(buf.buf, command)
    return buf
end

function time_commands()
    map(commands_and_buffers()) do (cmd, buf)
        @elapsed @eval run($cmd, $buf)
    end
end

# call methods for undo/redo
function changes()
    buf1::IOBuffer = IOBuffer(; read=true, write=true, append=true)
    buf2::VimBuffer = testbuf(TEST_STRING)
    for buf in (buf1, buf2)
        write(buf, TEST_STRING)
        record(buf)
        truncate(buf, 5)
        record(buf)
        undo!(buf)
        redo!(buf)
        reset!()
    end
end

"""
Run through the possible method calls to `junction_type` and `at_junction_type`
"""
function run_junctions()
    text_chars = TextChar[TextChar(' '), TextChar('a'), TextChar('!')]
    for (a, b) in permutations(text_chars)
        junction_type(a, b)
    end

    buf = testbuf("Hello Vim|!")

    is_word_start(buf)
    is_whitespace_start(buf)
    is_object_start(buf)
    is_word_end(buf)
    is_object_end(buf)
    is_whitespace_end(buf)
end

end

using PrecompileTools
# precompilation
@setup_workload begin
    commands = PkgTools.commands_and_buffers()
    @compile_workload begin
        for (cmd, buf) in commands
            well_formed(cmd)
            partial_well_formed(cmd)

            PkgTools.run(cmd, buf)
        end

        PkgTools.run_junctions()
        PkgTools.changes()
    end
end

