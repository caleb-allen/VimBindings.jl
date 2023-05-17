using PrecompileTools

@setup_workload begin
    """
    run a vim command on a buffer of text. Return a buffer of the result of the command
    """
    function run(buf::VimBuffer, cmd::String)
        command = parse_command(cmd)
        execute(buf.buf, command)
    end

    function run(test_string::String, command::String)
        buf = testbuf(test_string)
        return run(buf, command)
    end

    function run(command::String)
        buf = testbuf("""abcdefghijklmnopqrstuvwxyz "' 0987654321 A B C D E F G H| I J K L M N O P Q R S T U V W X Y Z 98 76 54 32 21 !@#%^9^&*() abcdefghijklmnopqrstuvwxyz '" 0987654321""")
        return run(buf, command)
    end

    function precompile_vim_commands()::Vector{String}
        s = """h j k l w W e E dh 5w daw cw ciw caW caw daW cW ct" fa a A i I o O x X C S dd D"""
        String.(split(s))
    end

    commands = precompile_vim_commands()
    @compile_workload begin
        for c in commands
            run(c)
        end
    end
end