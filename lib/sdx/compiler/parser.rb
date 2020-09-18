class State
    class << self
        attr_accessor :state
    end
    @@state = :ok
end

def error(msg)
    puts "\x1b[0;31mError in parser: #{msg}\x1b[0;0m"
end

module Parser

    class Lexer
        TOKENS = {
            /\A#.*/ => :comment,
            /\Aif/ => :if,
            /\Aelse/ => :else,
            /\Awhile/ => :while,
            /\Afor/ => :for,
            /\Ain/ => :in,
            /\Afn/ => :fn,
            /\Aobject/ => :object,
            /\Anew/ => :new,
            /\Arequire/ => :require,
            /\Areturn/ => :return,
            /\A(true|false)/ => :bool,
            /\A[0-9]+\.[0-9]+/ => :float,
            /\A[0-9]+/ => :number,
            /\A(\+|-)/ => :l1op,
            /\A(\/|\*|%|\^)/ => :l2op,
            /\A(<|>|<=|>=|==|!=)/ => :l1op,
            /\A(\+|-|\*|\/|%)?=/ => :eq,
            /\A"([^"]|\\")*"/ => :string,
            /\Anil/ => :nil,
            /\A\(/ => :lpar,
            /\A\)/ => :rpar,
            /\A\[/ => :lbrack,
            /\A\]/ => :rbrack,
            /\A\{/ => :lbrace,
            /\A\}/ => :rbrace,
            /\A,/ => :comma,
            /\A[A-Za-z_][A-Za-z0-9_]*([:.][A-Za-z_][A-Za-z0-9_]*)*/ => :name
        }

        class << self
            attr_accessor :lines
        end

        def self.lex(code)
            @@lines = code.split "\n"
            lexed = []
            comment = false
            line = col = 0
            State::state = :ok
            while State::state == :ok and code.size > 0
                while true
                    if code.size != 0 and code[0] == "\n"
                        col = 0
                        line += 1
                        code = code[1..-1]
                    elsif code.size != 0 and code[0].strip.empty?
                        if State::state == :ok
                            col += 1
                        end
                        code = code[1..-1]
                    else
                        break
                    end
                end
                if !comment && (code.start_with? "#>")
                    comment = true
                    code = code[2..-1]
                elsif comment && (code.start_with? "<#")
                    comment = false
                    code = code[2..-1]
                elsif comment
                    code = code[1..-1]
                else
                    found = false
                    TOKENS.each { |re, tag|
                        if (code =~ re) != nil
                            found = true
                            m = (re.match code)
                            if tag != :comment
                                lexed << [ m[0], tag, line, col ]
                            end
                            code = code[(m.end 0)..-1]
                            col += (m.end 0)
                            while true
                                if code.size != 0 and code[0] == "\n"
                                    col = 0
                                    line += 1
                                    code = code[1..-1]
                                elsif code.size != 0 and code[0].strip.empty?
                                    if State::state == :ok
                                        col += 1
                                    end
                                    code = code[1..-1]
                                else
                                    break
                                end
                            end
                            break
                        end
                    }
                    if !found
                        error %{
Invalid code at #{line}:#{col}
#{" " * line.to_s.size} |
#{line} | #{@@lines[line].rstrip}
#{" " * line.to_s.size} | #{" " * col}^ here}
                        State::state = :error
                    end
                end
            end
            [ lexed, @@lines ]
        end
    end

    class Node
        attr_reader :nodetype
        attr_reader :children
        attr_reader :value

        def initialize(nodetype, value = "", children = [])
            @nodetype = nodetype
            @value = value
            @children = children
        end
    end

    class Parser
        def self.lookahead(tokens, toktype, n)
            if n >= tokens.size
                return false
            end
            tokens[n][1] == toktype
        end

        def self.expect(tokens, toktype)
            self.lookahead(tokens, toktype, 0)
        end

        def self.parse_name(tokens)
            if self.expect tokens, :name
                [ (Node.new :name, tokens[0][0], []), 1 ]
            else
                nil
            end
        end

        def self.parse_nil(tokens)
            if self.expect tokens, :nil
                [ (Node.new :nil, tokens[0][0], []), 1 ]
            else
                nil
            end
        end

        def self.parse_number(tokens)
            negative = 0
            if tokens[0][0] == "-"
                tokens = tokens[1..-1]
                negative = 1
            end

            if self.expect tokens, :number
                [ (Node.new :number, ("-" * negative) + tokens[0][0], []), negative + 1 ]
            else
                nil
            end
        end

        def self.parse_bool(tokens)
            if self.expect tokens, :bool
                [ (Node.new :bool, tokens[0][0], []), 1 ]
            else
                nil
            end
        end

        def self.parse_float(tokens)
            negative = 0
            if tokens[0][0] == "-"
                tokens = tokens[1..-1]
                negative = 1
            end

            if self.expect tokens, :float
                [ (Node.new :float, ("-" * negative) + tokens[0][0], []), negative + 1 ]
            else
                nil
            end
        end

        def self.parse_string(tokens)
            if self.expect tokens, :string
                [ (Node.new :string, tokens[0][0][1..-2], []), 1 ]
            else
                nil
            end
        end

        def self.parse_parens(tokens)
            if self.expect tokens, :lpar
                tokens = tokens[1..-1]
                res = self.parse_expr tokens
                unless res
                    return nil
                end
                e, part = self.parse_expr tokens
                tokens = tokens[part..-1]
                res = self.expect tokens, :rpar
                unless res
                    return nil
                end
                return [e, part + 2]
            else
                return nil
            end
        end

        def self.parse_list(tokens)
            unless (self.expect tokens, :lbrack)
                return nil
            end
            tokens = tokens[1..-1]
            children = []
            total = 1
            while true
                if self.expect tokens, :rbrack
                    total += 1
                    break
                end
                res = self.parse_expr tokens
                unless res
                    return nil
                end
                e, part = res
                children << e
                total += part
                tokens = tokens[part..-1]
                if self.expect tokens, :rbrack
                    total += 1
                    break
                end
                unless (self.expect tokens, :comma)
                    return nil
                end
                total += 1
                tokens = tokens[1..-1]
            end
            [ (Node.new :list, "", children), total ]
        end

        def self.parse_block(tokens)
            unless (self.expect tokens, :lbrace)
                return nil
            end
            tokens = tokens[1..-1]
            children = []
            total = 1
            while true
                if self.expect tokens, :rbrace
                    total += 1
                    return [ (Node.new :block, "", children), total ]
                end
                e = self.parse_expr tokens
                if e
                    children << e[0]
                    total += e[1]
                    tokens = tokens[e[1]..-1]
                else
                    puts "Syntax error at token ", tokens[0]
                    Kernel.exit 1
                end
            end
            total += 1
            [ (Node.new :block, "", children), total ]
        end

        def self.parse_literal(tokens)
            (self.parse_block tokens) || 
            (self.parse_bool tokens) || 
            (self.parse_float tokens) || 
            (self.parse_name tokens) || 
            (self.parse_number tokens) || 
            (self.parse_list tokens) || 
            (self.parse_string tokens) || 
            (self.parse_nil tokens) || 
            (self.parse_parens tokens)
        end

        def self.parse_call(tokens)
            res = (self.parse_literal tokens)
            unless res
                return nil
            end
            callee = res
            total = callee[1]
            tokens = tokens[total..-1]
            callee = callee[0]
            if self.expect tokens, :lpar
                args = []
                tokens = tokens[1..-1]
                total += 1
                if self.expect tokens, :rpar
                    return [ (Node.new :call, callee, args), total + 1 ]
                end
                while true
                    res = (self.parse_expr tokens)
                    unless res
                        return nil
                    end
                    arg, part = res
                    total += part
                    tokens = tokens[part..-1]
                    args << arg
                    if self.expect tokens, :rpar
                        tokens = tokens[1..-1]
                        total += 1
                        break
                    end
                    unless (self.expect tokens, :comma)
                        return nil
                    end
                    total += 1
                    tokens = tokens[1..-1]
                end
                return [ (Node.new :call, callee, args), total ]
            else
                nil
            end
        end

        def self.parse_new(tokens)
            unless self.expect tokens, :new
                return nil
            end
            total = 1
            tokens = tokens[1..-1]
            if self.lookahead tokens, :lpar, 1
                res = (self.parse_literal tokens)
                unless res
                    return nil
                end
                callee = res
                callee = callee[0]
                args = []
                tokens = tokens[2..-1]
                total += 2
                if self.expect tokens, :rpar
                    return [ (Node.new :call, callee, args), total + 1 ]
                end
                while true
                    res = (self.parse_expr tokens)
                    unless res
                        return nil
                    end
                    arg, part = res
                    total += part
                    tokens = tokens[part..-1]
                    args << arg
                    total += 1
                    if self.expect tokens, :rpar
                        tokens = tokens[1..-1]
                        break
                    end
                    unless (self.expect tokens, :comma)
                        return nil
                    end
                    tokens = tokens[1..-1]
                end
                return [ (Node.new :new, callee, args), total ]
            else
                nil
            end
        end

        def self.parse_if(tokens)
            unless self.expect tokens, :if
                return nil
            end
            total = 1
            tokens = tokens[1..-1]
            res = self.parse_expr tokens
            unless res
                return nil
            end
            e, part = res
            total += part
            tokens = tokens[part..-1]
            res = self.parse_expr tokens
            unless res
                return nil
            end
            block, part = res
            total += part
            tokens = tokens[part..-1]
            el = nil
            if self.expect tokens, :else
                total += 1
                tokens = tokens[1..-1]
                res = self.parse_expr tokens
                unless res
                    return nil
                end
                el, part = res
                total += part
            end
            [ (Node.new :if, e, [block, el]), total ]
        end

        def self.parse_while(tokens)
            unless self.expect tokens, :while
                return nil
            end
            total = 1
            tokens = tokens[1..-1]
            res = self.parse_expr tokens
            unless res
                return nil
            end
            e, part = res
            total += part
            tokens = tokens[part..-1]
            res = self.parse_expr tokens
            unless res
                return nil
            end
            block, part = res
            total += part
            [ (Node.new :while, e, [block]), total ]
        end

        def self.parse_for(tokens)
            unless self.expect tokens, :for
                return nil
            end
            total = 1
            tokens = tokens[1..-1]
            name = nil
            if self.expect tokens, :name and self.lookahead tokens, :in, 1
                name = tokens[0][0]
                total += 2
                tokens = tokens[2..-1]
            end
            res = self.parse_expr tokens
            unless res
                return nil
            end
            e, part = res
            total += part
            tokens = tokens[part..-1]
            res = self.parse_expr tokens
            unless res
                return nil
            end
            block, part = res
            total += part
            [ (Node.new :for, e, [name, block]), total ]
        end

        def self.parse_factor(tokens)
            (self.parse_call tokens) || 
            (self.parse_require tokens) || 
            (self.parse_new tokens) || 
            (self.parse_object tokens) || 
            (self.parse_fn tokens) || 
            (self.parse_assign tokens) || 
            (self.parse_literal tokens) || 
            (self.parse_if tokens) || 
            (self.parse_while tokens) || 
            (self.parse_for tokens)
        end

        def self.parse_term(tokens)
            total = 0
            res = self.parse_factor tokens
            unless res
                return nil
            end
            lhs, part = res
            total += part
            tokens = tokens[part..-1]
            unless self.expect tokens, :l2op
                return [lhs, part]
            end
            op = tokens[0][0]
            total += 1
            tokens = tokens[1..-1]
            res = self.parse_factor tokens
            unless res
                return nil
            end
            rhs, part = res
            total += part
            tokens = tokens[part..-1]
            out = (Node.new :op, op, [lhs])
            while self.expect tokens, :l2op
                op = tokens[0][0]
                total += 1
                tokens = tokens[1..-1]
                res = self.parse_term tokens
                unless res
                    return nil
                end
                rhs2, part = res
                total += part
                tokens = tokens[part..-1]
                rhs = Node.new :op, op, [rhs, rhs2]
            end
            out.children << rhs
            [out, total]
        end

        def self.parse_op(tokens)
            total = 0
            res = self.parse_term tokens
            unless res
                return nil
            end
            lhs, part = res
            total += part
            tokens = tokens[part..-1]
            unless self.expect tokens, :l1op
                return [lhs, part]
            end
            op = tokens[0][0]
            total += 1
            tokens = tokens[1..-1]
            res = self.parse_term tokens
            unless res
                return nil
            end
            rhs, part = res
            total += part
            tokens = tokens[part..-1]
            out = (Node.new :op, op, [lhs])
            while self.expect tokens, :l1op
                op = tokens[0][0]
                total += 1
                tokens = tokens[1..-1]
                res = self.parse_term tokens
                unless res
                    return nil
                end
                rhs2, part = res
                total += part
                tokens = tokens[part..-1]
                rhs = Node.new :op, op, [rhs, rhs2]
            end
            out.children << rhs
            [out, total]
        end

        def self.parse_assign(tokens)
            total = 0
            unless self.expect tokens, :name
                return nil
            end
            name = tokens[0][0]
            total += 1
            tokens = tokens[1..-1]
            unless self.expect tokens, :eq
                return nil
            end
            eq = tokens[0][0]
            total += 1
            tokens = tokens[1..-1]
            res = self.parse_expr tokens
            unless res
                return nil
            end
            rhs, part = res
            total += part
            [ (Node.new :assign, eq, [name, rhs]), total]
        end

        def self.parse_fn(tokens)
            unless self.expect tokens, :fn
                return nil
            end
            total = 1
            tokens = tokens[1..-1]
            unless self.expect tokens, :name
                return nil
            end
            name = tokens[0][0]
            total += 1
            tokens = tokens[1..-1]
            unless self.expect tokens, :lpar
                return nil
            end
            total += 1
            tokens = tokens[1..-1]
            args = []
            while true
                if self.expect tokens, :rpar
                    total += 1
                    tokens = tokens[1..-1]
                    break
                end
                unless self.expect tokens, :name
                    return nil
                end
                args << tokens[0][0]
                total += 1
                tokens = tokens[1..-1]
                if self.expect tokens, :rpar
                    total += 1
                    tokens = tokens[1..-1]
                    break
                end
                unless self.expect tokens, :comma
                    return nil
                end
                total += 1
                tokens = tokens[1..-1]
            end
            res = self.parse_expr tokens
            unless res
                return nil
            end
            body, part = res
            total += part
            [ (Node.new :fn, name, [args, body]), total ]
        end

        def self.parse_object(tokens)
            unless self.expect tokens, :object
                return nil
            end
            total = 1
            tokens = tokens[1..-1]
            unless self.expect tokens, :name
                return nil
            end
            name = tokens[0][0]
            total += 1
            tokens = tokens[1..-1]
            args = []
            if self.expect tokens, :lpar
                total += 1
                tokens = tokens[1..-1]
                while true
                    if self.expect tokens, :rpar
                        total += 1
                        tokens = tokens[1..-1]
                        break
                    end
                    unless self.expect tokens, :name
                        return nil
                    end
                    args << tokens[0][0]
                    total += 1
                    tokens = tokens[1..-1]
                    if self.expect tokens, :rpar
                        total += 1
                        tokens = tokens[1..-1]
                        break
                    end
                    unless self.expect tokens, :comma
                        return nil
                    end
                    total += 1
                    tokens = tokens[1..-1]
                end
            end
            res = self.parse_expr tokens
            unless res
                return nil
            end
            body, part = res
            total += part
            [ (Node.new :object, name, [args, body]), total ]
        end

        def self.parse_require(tokens)
            unless self.expect tokens, :require
                return nil
            end
            tokens = tokens[1..-1]
            unless self.expect tokens, :string
                return nil
            end
            [ (Node.new :require, tokens[0][0][1..-2], []), 2 ]
        end

        def self.parse_return(tokens)
            unless self.expect tokens, :return
                return nil
            end
            tokens = tokens[1..-1]
            res = self.parse_expr tokens
            unless res
                return nil
            end
            [ (Node.new :return, res[0], []), res[1] ]
        end
            
        def self.parse_expr(tokens)
            (self.parse_op tokens)  || 
            (self.parse_call tokens) || 
            (self.parse_require tokens) || 
            (self.parse_return tokens) ||
            (self.parse_new tokens) || 
            (self.parse_object tokens) || 
            (self.parse_fn tokens) || 
            (self.parse_assign tokens) || 
            (self.parse_literal tokens) || 
            (self.parse_if tokens) || 
            (self.parse_while tokens) || 
            (self.parse_for tokens)
        end

        def self.parse(tokens, path, lines)
            parsed = []
            while State::state == :ok and tokens.size > 0
                e = self.parse_expr tokens
                if e
                    if e[0].nodetype == :require
                        code = nil
                        path.each do |search|
                            begin
                                code = File.read "#{File.join(search, e[0].value)}.sdx"
                            rescue
                                nil
                            end
                        end
                        unless code
                            error "Cannot find file #{e[0].value}.sdx anywhere in path"
                            State::state = :error
                            return nil
                        end
                        tokens = tokens[e[1]..-1]
                        lexed, _ = Lexer.lex code
                        tokens = [*lexed, *tokens]
                    else
                        parsed << e[0]
                        tokens = tokens[e[1]..-1]
                    end
                else
                    error %{
Unexpected token #{tokens[0][1]} at #{tokens[0][2]}:#{tokens[0][3]}
#{" " * tokens[0][2].to_s.size} |
#{tokens[0][2]} | #{lines[tokens[0][2]].rstrip}
#{" " * tokens[0][2].to_s.size} | #{" " * tokens[0][3]}^ here}
                    State::state = :error
                end
            end
            parsed
        end
    end
end