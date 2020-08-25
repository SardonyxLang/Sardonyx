#!/usr/bin/ruby
require "./compiler/parser"
require "./compiler/compiler"
require "./vm/vm"

if ARGV.size == 1
    code = File.read ARGV[0]
    lexed = Parser::Lexer.lex code
    ast = Parser::Parser.parse lexed
    bc = Compiler::Compiler.compile ast
    vm = VM.new StringIO.new bc
    vm.interpret
else
    vm = VM.new StringIO.new ""
    puts "Sardonyx v 0.0.1"
    def exit(_) end
    loop do
        print "> "
        code = gets
        lexed = Parser::Lexer.lex code
        ast = Parser::Parser.parse lexed
        bc = Compiler::Compiler.compile ast
        vm.bc_io = StringIO.new bc
        vm.byte_pos = 0
        vm.interpret
    end
end