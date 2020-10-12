require "./parser"
require "./compiler"
require "./vm"
require "./error"
require "readline"
require "option_parser"

module SDX
    class CLI
        def self.run(filename : String?, emit_bc : Bool)
            if filename
                code = File.read(filename.as String)
                ast = Parser::Parser.parse code.as String
                if ast
                    bc = Compiler.compile ast
                    if emit_bc
                        new_file = filename.as(String).split('.')[0] + ".sdxc"
                        File.write new_file, bc
                        return
                    end
                    vm = VM.new IO::Memory.new bc
                    vm.run
                end
            else
                puts "Sardonyx v 1.0.0-beta"
                Lookup.warn
                vm = VM.new IO::Memory.new ""
                loop do
                    code = Readline.readline "> "
                    Error.no_exit = true
                    case code
                    when nil
                        puts ":exit"
                        exit
                    when ":exit"
                        exit
                    when ":help"
                        puts "See https://sardonyxlang.github.io/docs for documentation - for now, try running `5 + 5`"
                    else
                        ast = Parser::Parser.parse code.as String
                        if ast
                            bc = Compiler.compile ast, false
                            if emit_bc
                                bc.chars.each do |char|
                                    if 0x20 <= char.ord <= 0x7e
                                        print char
                                    else
                                        print "\\x#{char.ord}"
                                    end
                                end
                                puts
                            else
                                vm.bc = IO::Memory.new bc
                                vm.offset = 0
                                ret = vm.run
                                val = vm.stack[-1]?
                                vm.clear
                                if val && ret == :ok
                                    puts VM.stringify val
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end

emit_bc = false
files = [] of String

OptionParser.parse do |parser|
    parser.banner = "Welcome to Sardonyx!"
  
    parser.on "-v", "--version", "Show version" do
        puts "Sardonyx v1.0.0-beta"
        exit
    end

    parser.on "-h", "--help", "Show help" do
        puts parser
        exit
    end

    parser.on "-b", "---bytecode", "Emit bytecode" do
        emit_bc = true
    end

    parser.unknown_args do |argv|
        files = argv
    end

    parser.missing_option do |option_flag|
        SDX::Error.cli_error "Invalid option #{option_flag}, use -h for help"
    end

    parser.invalid_option do |option_flag|
        SDX::Error.cli_error "Invalid option #{option_flag}, use -h for help"
    end
end

if files.size == 0
    SDX::CLI.run nil, emit_bc
else
    files.each do |file|
        SDX::CLI.run file, emit_bc
    end
end