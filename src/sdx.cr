require "./parser"
require "./compiler"
require "./vm"
require "readline"

module SDX
    class CLI
        def self.run(filename : String?)
            if filename
                code = File.read(filename.as String)
                ast = Parser::Parser.parse code.as String
                if ast
                    bc = Compiler.compile ast
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

SDX::CLI.run ARGV[0]?