module Parser
    class Lexer
        TOKENS = {
            /\Aif/ => :if,
            /\Aelse/ => :else,
            /\Awhile/ => :while,
            /\Afor/ => :for,
            /\Ain/ => :in,
            /\Afn/ => :fn,
            /\Aobject/ => :object,
            /\Anew/ => :new,
            /\Arequire/ => :require,
            /\A(<|>|<=|>=|==|!=)/ => :op,
            /\A(\+|-|\*|\/|%)?=/ => :eq,
            /\A(\+|-|\*|\/|%)/ => :op,
            /\A-?[0-9]+/ => :number,
            /\A-?[0-9]+\.[0-9]+/ => :float,
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

        def self.lex(code)
            lexed = []
            found = false
            while code.size > 0
                TOKENS.each { |re, tag|
                    if (code =~ re) != nil
                        found = true
                        m = (re.match code)
                        lexed << [ m[0], tag ]
                        code = code[(m.end 0)..code.size].lstrip
                        break
                    end
                }
                if !found
                    puts "Syntax error: ", code
                    Kernel.exit 1
                end
            end
            lexed
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
            if self.expect tokens, :number
                [ (Node.new :number, tokens[0][0], []), 1 ]
            else
                nil
            end
        end

        def self.parse_float(tokens)
            if self.expect tokens, :float
                [ (Node.new :float, tokens[0][0], []), 1 ]
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
                tokens = tokens[1..tokens.size]
                unless self.parse_expr tokens
                    return nil
                end
                e, part = self.parse_expr tokens
                tokens = tokens[part..tokens.size]
                unless self.expect tokens, :rpar
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
            tokens = tokens[1..tokens.size]
            children = []
            total = 1
            while true
                if self.expect tokens, :rbrack
                    total += 1
                    break
                end
                unless self.parse_expr tokens
                    return nil
                end
                e, part = self.parse_expr tokens
                children << e
                total += part
                tokens = tokens[part..tokens.size]
                if self.expect tokens, :rbrack
                    total += 1
                    break
                end
                unless (self.expect tokens, :comma)
                    return nil
                end
                total += 1
                tokens = tokens[1..tokens.size]
            end
            [ (Node.new :list, "", children), total ]
        end

        def self.parse_block(tokens)
            unless (self.expect tokens, :lbrace)
                return nil
            end
            tokens = tokens[1..tokens.size]
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
                    tokens = tokens[e[1]..tokens.size]
                else
                    puts "Syntax error at token ", tokens[0]
                    Kernel.exit 1
                end
            end
            total += 1
            [ (Node.new :block, "", children), total ]
        end

        def self.parse_literal(tokens)
            (self.parse_block tokens) ||  (self.parse_float tokens) || (self.parse_name tokens) || (self.parse_number tokens) || (self.parse_list tokens) || (self.parse_string tokens) || (self.parse_nil tokens) || (self.parse_parens tokens)
        end

        def self.parse_call(tokens)
            unless (self.parse_literal tokens)
                return nil
            end
            callee = (self.parse_literal tokens)
            total = callee[1]
            tokens = tokens[total..tokens.size]
            callee = callee[0]
            if self.expect tokens, :lpar
                args = []
                tokens = tokens[1..tokens.size]
                total += 1
                if self.expect tokens, :rpar
                    return [ (Node.new :call, callee, args), total + 1 ]
                end
                while true
                    unless (self.parse_expr tokens)
                        return nil
                    end
                    arg, part = (self.parse_expr tokens)
                    total += part
                    tokens = tokens[part..tokens.size]
                    args << arg
                    total += 1
                    if self.expect tokens, :rpar
                        tokens = tokens[1..tokens.size]
                        break
                    end
                    unless (self.expect tokens, :comma)
                        return nil
                    end
                    tokens = tokens[1..tokens.size]
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
            tokens = tokens[1..tokens.size]
            if self.lookahead tokens, :lpar, 1
                unless (self.parse_literal tokens)
                    return nil
                end
                callee = (self.parse_literal tokens)
                callee = callee[0]
                args = []
                tokens = tokens[2..tokens.size]
                total += 2
                if self.expect tokens, :rpar
                    return [ (Node.new :call, callee, args), total + 1 ]
                end
                while true
                    unless (self.parse_expr tokens)
                        return nil
                    end
                    arg, part = (self.parse_expr tokens)
                    total += part
                    tokens = tokens[part..tokens.size]
                    args << arg
                    total += 1
                    if self.expect tokens, :rpar
                        tokens = tokens[1..tokens.size]
                        break
                    end
                    unless (self.expect tokens, :comma)
                        return nil
                    end
                    tokens = tokens[1..tokens.size]
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
            tokens = tokens[1..tokens.size]
            unless self.parse_expr tokens
                return nil
            end
            e, part = self.parse_expr tokens
            total += part
            tokens = tokens[part..tokens.size]
            unless self.parse_expr tokens
                return nil
            end
            block, part = self.parse_expr tokens
            total += part
            tokens = tokens[part..tokens.size]
            el = nil
            if self.expect tokens, :else
                total += 1
                tokens = tokens[1..tokens.size]
                unless self.parse_expr tokens
                    return nil
                end
                el, part = self.parse_expr tokens 
                total += part
            end
            return [ (Node.new :if, e, [block, el]), total ]
        end

        def self.parse_while(tokens)
            unless self.expect tokens, :while
                return nil
            end
            total = 1
            tokens = tokens[1..tokens.size]
            unless self.parse_expr tokens
                return nil
            end
            e, part = self.parse_expr tokens
            total += part
            tokens = tokens[part..tokens.size]
            unless self.parse_expr tokens
                return nil
            end
            block, part = self.parse_expr tokens
            total += part
            return [ (Node.new :while, e, [block]), total ]
        end

        def self.parse_for(tokens)
            unless self.expect tokens, :for
                return nil
            end
            total = 1
            tokens = tokens[1..tokens.size]
            name = nil
            if self.expect tokens, :name and self.lookahead tokens, :in, 1
                name = tokens[0][0]
                total += 2
                tokens = tokens[2..tokens.size]
            end
            unless self.parse_expr tokens
                return nil
            end
            e, part = self.parse_expr tokens
            total += part
            tokens = tokens[part..tokens.size]
            unless self.parse_expr tokens
                return nil
            end
            block, part = self.parse_expr tokens
            total += part
            return [ (Node.new :for, e, [name, block]), total ]
        end

        def self.parse_op(tokens)
            total = 0
            unless self.parse_literal tokens
                return nil
            end
            lhs, part = self.parse_literal tokens
            total += part
            tokens = tokens[part..tokens.size]
            unless self.expect tokens, :op
                return nil
            end
            op = tokens[0][0]
            total += 1
            tokens = tokens[1..tokens.size]
            unless self.parse_expr tokens
                return nil
            end
            rhs, part = self.parse_expr tokens
            total += part
            return [ (Node.new :op, op, [lhs, rhs]), total]
        end

        def self.parse_assign(tokens)
            total = 0
            unless self.expect tokens, :name
                return nil
            end
            name = tokens[0][0]
            total += 1
            tokens = tokens[1..tokens.size]
            unless self.expect tokens, :eq
                return nil
            end
            eq = tokens[0][0]
            total += 1
            tokens = tokens[1..tokens.size]
            unless self.parse_expr tokens
                return nil
            end
            rhs, part = self.parse_expr tokens
            total += part
            return [ (Node.new :assign, eq, [name, rhs]), total]
        end

        def self.parse_fn(tokens)
            unless self.expect tokens, :fn
                return nil
            end
            total = 1
            tokens = tokens[1..tokens.size]
            unless self.expect tokens, :name
                return nil
            end
            name = tokens[0][0]
            total += 1
            tokens = tokens[1..tokens.size]
            unless self.expect tokens, :lpar
                return nil
            end
            total += 1
            tokens = tokens[1..tokens.size]
            args = []
            while true
                if self.expect tokens, :rpar
                    total += 1
                    tokens = tokens[1..tokens.size]
                    break
                end
                unless self.expect tokens, :name
                    return nil
                end
                args << tokens[0][0]
                total += 1
                tokens = tokens[1..tokens.size]
                if self.expect tokens, :rpar
                    total += 1
                    tokens = tokens[1..tokens.size]
                    break
                end
                unless self.expect tokens, :comma
                    return nil
                end
                total += 1
                tokens = tokens[1..tokens.size]
            end
            unless self.parse_expr tokens
                return nil
            end
            body, part = self.parse_expr tokens
            total += part
            return [ (Node.new :fn, name, [args, body]), total ]
        end

        def self.parse_object(tokens)
            unless self.expect tokens, :object
                return nil
            end
            total = 1
            tokens = tokens[1..tokens.size]
            unless self.expect tokens, :name
                return nil
            end
            name = tokens[0][0]
            total += 1
            tokens = tokens[1..tokens.size]
            args = []
            if self.expect tokens, :lpar
                total += 1
                tokens = tokens[1..tokens.size]
                while true
                    if self.expect tokens, :rpar
                        total += 1
                        tokens = tokens[1..tokens.size]
                        break
                    end
                    unless self.expect tokens, :name
                        return nil
                    end
                    args << tokens[0][0]
                    total += 1
                    tokens = tokens[1..tokens.size]
                    if self.expect tokens, :rpar
                        total += 1
                        tokens = tokens[1..tokens.size]
                        break
                    end
                    unless self.expect tokens, :comma
                        return nil
                    end
                    total += 1
                    tokens = tokens[1..tokens.size]
                end
            end
            unless self.parse_expr tokens
                return nil
            end
            body, part = self.parse_expr tokens
            total += part
            return [ (Node.new :object, name, [args, body]), total ]
        end

        def self.parse_require(tokens)
            unless self.expect tokens, :require
                return nil
            end
            tokens = tokens[1..tokens.size]
            unless self.expect tokens, :string
                return nil
            end
            return [ (Node.new :require, tokens[0][0][1..-2], []), 2 ]
        end
            
        def self.parse_expr(tokens)
            (self.parse_require tokens) || (self.parse_new tokens) || (self.parse_object tokens) || (self.parse_fn tokens) || (self.parse_assign tokens) || (self.parse_op tokens)  || (self.parse_call tokens) || (self.parse_literal tokens) || (self.parse_if tokens) || (self.parse_while tokens) || (self.parse_for tokens)
        end

        def self.parse(tokens, path)
            parsed = []
            while tokens.size > 0
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
                            puts "Cannot find file #{e[0].value}.sdx anywhere in path"
                            Kernel.exit 1
                        end
                        lexed = Lexer.lex code
                        ast = self.parse lexed, path
                        parsed.concat ast
                    else
                        parsed << e[0]
                    end
                    tokens = tokens[e[1]..tokens.size]
                else
                    puts "Syntax error at token ", tokens[0][1]
                    Kernel.exit 1
                end
            end
            parsed
        end
    end
end