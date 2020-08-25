#!/usr/bin/ruby
require "./compiler/parser"
require "./compiler/compiler"
require "./vm/vm"

if ARGV.size == 1
    path = [(File.expand_path File.dirname ARGV[0]), *(ENV.fetch("SDX_PATH", "").split ":")]
    code = File.read ARGV[0]
    lexed = Parser::Lexer.lex code
    ast = Parser::Parser.parse lexed, path
    bc = Compiler::Compiler.compile ast
    vm = VM.new StringIO.new bc
    vm.interpret
else
    path = [(File.expand_path Dir.pwd), *(ENV.fetch("SDX_PATH", "").split ":")]
    vm = VM.new StringIO.new ""
    puts "Sardonyx v 0.0.1"
    def exit(_) end
    loop do
        print "> "
        code = gets
        lexed = Parser::Lexer.lex code
        ast = Parser::Parser.parse lexed, path
        bc = Compiler::Compiler.compile ast
        vm.bc_io = StringIO.new bc
        vm.byte_pos = 0
        vm.interpret
    end
end