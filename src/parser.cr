require "./error"
require "./lookup"

module SDX::Parser
    enum Tag
        Comment
        If
        Else
        While
        For
        In
        Fn
        Object
        New
        Require
        Return
        Bool
        Num
        Int
        L1op
        L2op
        Eq
        Str
        Nil
        Lpar
        Rpar
        Lbrack
        Rbrack
        Lbrace
        Rbrace
        Comma
        Dot
        Name
    end

    alias Token = { String, Tag }

    class Lexer
        TOKENS = {
            /\A#>.*?<#/m => Tag::Comment,
            /\A#.*/ => Tag::Comment,
            /\Aif/ => Tag::If,
            /\Aelse/ => Tag::Else,
            /\Awhile/ => Tag::While,
            /\Afor/ => Tag::For,
            /\Ain/ => Tag::In,
            /\Afn/ => Tag::Fn,
            /\Aobject/ => Tag::Object,
            /\Anew/ => Tag::New,
            /\Arequire/ => Tag::Require,
            /\Areturn/ => Tag::Return,
            /\A(true|false)/ => Tag::Bool,
            /\A[0-9]+\.[0-9]+/ => Tag::Num,
            /\A[0-9]+/ => Tag::Int,
            /\A(\+|-)/ => Tag::L1op,
            /\A(\/|\*|%|\^)/ => Tag::L2op,
            /\A(<|>|<=|>=|==|!=)/ => Tag::L1op,
            /\A=/ => Tag::Eq,
            /\A"([^"]|\\")*"/ => Tag::Str,
            /\Anil/ => Tag::Nil,
            /\A\(/ => Tag::Lpar,
            /\A\)/ => Tag::Rpar,
            /\A\[/ => Tag::Lbrack,
            /\A\]/ => Tag::Rbrack,
            /\A\{/ => Tag::Lbrace,
            /\A\}/ => Tag::Rbrace,
            /\A,/ => Tag::Comma,
            /\A\./ => Tag::Dot,
            /\A[A-Za-z_][A-Za-z0-9_]*(:[A-Za-z_][A-Za-z0-9_]*)*/ => Tag::Name
        }

        def self.lex(code : String)
            lexed = [] of Token
            while code != ""
                found = false
                TOKENS.each do |re, tag|
                    unless found
                        unless (m = (re.match code)).nil?
                            found = true
                            if tag != Tag::Comment
                                lexed << { m[0], tag }
                            end
                            code = code[(m.end 0)..].lstrip
                        end
                    end
                end
                unless found
                    Error.lexer_error "Invalid code"
                    return nil
                end
            end
            lexed
        end
    end

    abstract class Node
        getter children : Array(Node) = [] of Node

        def initialize(children : Array(Node))
            @children = children
        end
    end
    
    private macro single_node_type(t)
        class {{t}}Node < Node
            getter value : String

            def initialize(value : String)
                @value = value
            end
        end
    end

    single_node_type Int
    single_node_type Num
    single_node_type Name
    single_node_type Nil
    single_node_type Bool
    single_node_type Str

    class AccessNode < Node
        getter value : Node
        getter fields : Array(String)

        def initialize(value : Node, fields : Array(String))
            @value = value
            @fields = fields
        end
    end

    class ListNode < Node
    end

    class BlockNode < Node
    end

    class CallNode < Node
        getter value : Node
        
        def initialize(value : Node, children : Array(Node))
            @value = value
            @children = children
        end
    end

    class NewNode < Node
        getter value : Node
        
        def initialize(value : Node, children : Array(Node))
            @value = value
            @children = children
        end
    end

    class AssignNode < Node
        getter name : String
        getter value : Node
        
        def initialize(name : String, value : Node)
            @name = name
            @value = value
        end
    end
    
    class IfNode < Node
        getter cond : Node
        getter body : Node
        getter other : Node?

        def initialize(cond : Node, body : Node, other : Node?)
            @cond = cond
            @body = body
            @other = other
        end
    end

    class WhileNode < Node
        getter cond : Node
        getter body : Node

        def initialize(cond : Node, body : Node)
            @cond = cond
            @body = body
        end
    end
    
    class ForNode < Node
        getter value : Node
        getter name : String?
        getter body : Node

        def initialize(value : Node, name : String?, body : Node)
            @value = value
            @name = name
            @body = body
        end
    end

    class OpNode < Node
        getter op : String
        getter operands : Array(Node)

        def initialize(op : String, operands : Array(Node))
            @op = op
            @operands = operands
        end
    end

    class FnNode < Node
        getter name : String
        getter args : Array(Node)
        getter body : Node

        def initialize(name : String, args : Array(Node), body : Node)
            @name = name
            @args = args
            @body = body
        end
    end

    class ObjectNode < Node
        getter name : String
        getter args : Array(Node)?
        getter body : Node

        def initialize(name : String, args : Array(Node)?, body : Node)
            @name = name
            @args = args
            @body = body
        end
    end

    class RequireNode < Node
        getter path : String

        def initialize(path : String)
            @path = path
        end
    end

    class IndexNode < Node
        getter value : Node
        getter index : Node

        def initialize(value : Node, index : Node)
            @value = value
            @index = index
        end
    end

    class Parser
        def self.lookahead(tokens : Array(Token), type : Tag, n : Int32)
            if n >= tokens.size
                nil
            else
                tokens[n][1] == type ? tokens[n][0] : nil
            end
        end

        def self.expect(tokens : Array(Token), type : Tag)
            self.lookahead tokens, type, 0
        end

        private macro single_node_method(t)
            def self.parse_{{t.id.downcase}}(tokens : Array(Token))
                unless val = self.expect tokens, Tag::{{t}}
                    return nil
                end
                { {{t}}Node.new(val), 1 }
            end
        end

        def self.parse_int(tokens : Array(Token))
            negative = 0
            if tokens[0][0] == "-"
                tokens = tokens[1..-1]
                negative = 1
            end
            unless val = self.expect tokens, Tag::Int
                return nil
            end
            { IntNode.new(("-" * negative) + val), negative + 1 }
        end
        def self.parse_num(tokens : Array(Token))
            negative = 0
            if tokens[0][0] == "-"
                tokens = tokens[1..-1]
                negative = 1
            end
            unless val = self.expect tokens, Tag::Num
                return nil
            end
            { NumNode.new(("-" * negative) + val), negative + 1 }
        end
        single_node_method Name
        single_node_method Nil
        single_node_method Bool
        single_node_method Str

        def self.parse_access(tokens : Array(Token))
            children = [] of String

            unless first = self.parse_literal tokens
                return nil
            end
            first, first_part = first
            total = first_part
            tokens = tokens[first_part..]

            unless self.expect tokens, Tag::Dot
                return nil
            end
            total += 1
            tokens = tokens[1..]
            
            unless name = self.expect tokens, Tag::Name
                return nil
            end
            children << name
            total += 1
            tokens = tokens[1..]

            loop do
                unless self.expect tokens, Tag::Dot
                    break
                end
                total += 1
                tokens = tokens[1..]

                unless name = self.expect tokens, Tag::Name
                    break
                end
                children << name
                total += 1
                tokens = tokens[1..]
            end

            { AccessNode.new(first, children), total }
        end

        def self.parse_assign(tokens : Array(Token))
            unless name = self.expect tokens, Tag::Name
                return nil
            end
            tokens = tokens[1..]
            unless self.expect tokens, Tag::Eq
                return nil
            end
            tokens = tokens[1..]
            total = 2
            unless val = self.parse_expr(tokens)
                return nil
            end
            val, val_part = val
            { AssignNode.new(name, val), total + val_part }
        end

        def self.get_sequence(
                tokens : Array(Token), 
                start : Tag, 
                ending : Tag, 
                &method : Array(Token) -> { Node, Int32 }?
            )
            seq = [] of Node
            total = 1
            unless self.expect tokens, start
                return nil
            end
            tokens = tokens[1..]
            if self.expect tokens, ending
                return { seq, total + 1 }
            end
            loop do
                unless item = method.call tokens
                    return nil
                end
                item, item_part = item
                seq << item
                total += item_part
                tokens = tokens[item_part..]
                if self.expect tokens, ending
                    return { seq, total + 1 }
                end
                unless self.expect tokens, Tag::Comma
                    return nil
                end
                tokens = tokens[1..]
                total += 1
            end
        end

        def self.parse_list(tokens : Array(Token))
            unless seq = self.get_sequence tokens, Tag::Lbrack, Tag::Rbrack do |tokens|
                self.parse_expr tokens
            end
                return nil
            end
            seq, seq_part = seq
            { ListNode.new(seq), seq_part }
        end

        def self.parse_block(tokens : Array(Token))
            unless self.expect tokens, Tag::Lbrace
                return nil
            end
            total = 1
            tokens = tokens[1..]
            children = [] of Node
            loop do
                unless expr = self.parse_expr tokens
                    Error.parser_error "Expected expression"
                    return nil
                end
                expr, expr_part = expr.as { Node, Int32 }
                children << expr
                total += expr_part
                tokens = tokens[expr_part..]
                if self.expect tokens, Tag::Rbrace
                    return { BlockNode.new(children), total + 1 }
                end
            end
        end

        def self.parse_call(tokens : Array(Token))
            unless callee = self.parse_access(tokens) || self.parse_literal(tokens)
                return nil
            end
            callee, callee_part = callee
            tokens = tokens[callee_part..]
            unless args = self.get_sequence tokens, Tag::Lpar, Tag::Rpar do |tokens|
                self.parse_expr tokens
            end
                return nil
            end
            args, args_part = args
            { CallNode.new(callee, args), callee_part + args_part }
        end

        def self.parse_new(tokens : Array(Token))
            unless self.expect tokens, Tag::New
                return nil
            end
            tokens = tokens[1..]
            unless callee = self.parse_literal tokens
                return nil
            end
            callee, callee_part = callee
            tokens = tokens[callee_part..]
            unless args = self.get_sequence tokens, Tag::Lpar, Tag::Rpar do |tokens|
                self.parse_expr tokens
            end
                return nil
            end
            args, args_part = args
            { NewNode.new(callee, args), 1 + callee_part + args_part }
        end

        def self.parse_if(tokens : Array(Token))
            unless self.expect tokens, Tag::If
                return nil
            end
            tokens = tokens[1..]
            total = 1

            unless cond = self.parse_expr tokens
                return nil
            end
            cond, cond_part = cond
            total += cond_part
            tokens = tokens[cond_part..]

            unless body = self.parse_expr tokens
                return nil
            end
            body, body_part = body
            total += body_part
            tokens = tokens[body_part..]

            other = nil

            if self.expect tokens, Tag::Else
                total += 1
                tokens = tokens[1..]
                unless other = self.parse_expr tokens
                    return nil
                end
                other, other_part = other
                total += other_part
            end

            { IfNode.new(cond, body, other), total }
        end

        def self.parse_while(tokens : Array(Token))
            unless self.expect tokens, Tag::While
                return nil
            end
            tokens = tokens[1..]
            total = 1

            unless cond = self.parse_expr tokens
                return nil
            end
            cond, cond_part = cond
            total += cond_part
            tokens = tokens[cond_part..]

            unless body = self.parse_expr tokens
                return nil
            end
            body, body_part = body
            total += body_part

            { WhileNode.new(cond, body), total }
        end

        def self.parse_for(tokens : Array(Token))
            unless self.expect tokens, Tag::For
                return nil
            end
            tokens = tokens[1..]
            total = 1

            name = nil
            if self.lookahead tokens, Tag::In, 1
                unless name = self.expect tokens, Tag::Name
                    return nil
                end
                total += 2
                tokens = tokens[2..]
            end

            unless iter = self.parse_expr tokens
                return nil
            end
            iter, iter_part = iter
            total += iter_part
            tokens = tokens[iter_part..]

            unless body = self.parse_expr tokens
                return nil
            end
            body, body_part = body
            total += body_part

            { ForNode.new(iter, name, body), total }
        end

        def self.parse_index(tokens)
            unless list = self.parse_literal tokens
                return nil
            end
            list, list_part = list
            total = list_part
            tokens = tokens[list_part..]

            unless self.expect tokens, Tag::Lbrack
                return nil
            end
            total += 1
            tokens = tokens[1..]

            unless index = self.parse_expr tokens
                return nil
            end
            index, index_part = index
            total += index_part
            tokens = tokens[index_part..]

            unless self.expect tokens, Tag::Rbrack
                return nil
            end

            { IndexNode.new(list, index), total + 1 }
        end

        def self.parse_literal(tokens : Array(Token))
            self.parse_int(tokens) ||
            self.parse_num(tokens) ||
            self.parse_name(tokens) ||
            self.parse_nil(tokens) ||
            self.parse_bool(tokens) ||
            self.parse_str(tokens) ||
            self.parse_list(tokens) ||
            self.parse_block(tokens)
        end

        def self.parse_factor(tokens)
            self.parse_for(tokens) ||
            self.parse_while(tokens) ||
            self.parse_if(tokens) ||
            self.parse_new(tokens) ||
            self.parse_call(tokens) ||
            self.parse_assign(tokens) ||
            self.parse_index(tokens) ||
            self.parse_access(tokens) ||
            self.parse_literal(tokens)
        end

        def self.parse_term(tokens)
            total = 0
            unless lhs = self.parse_factor tokens
                return nil
            end
            lhs, lhs_part = lhs
            total += lhs_part
            tokens = tokens[lhs_part..]
            unless self.expect tokens, Tag::L2op
                return { lhs, total }
            end
            op = tokens[0][0]
            total += 1
            tokens = tokens[1..]
            unless rhs = self.parse_factor tokens
                return nil
            end
            rhs, rhs_part = rhs
            total += rhs_part
            tokens = tokens[rhs_part..]
            final = OpNode.new op, [lhs]
            while self.expect tokens, Tag::L2op
                op = tokens[0][0]
                total += 1
                tokens = tokens[1..]
                unless rhs2 = self.parse_term tokens
                    return nil
                end
                rhs2, rhs2_part = rhs2
                total += rhs2_part
                tokens = tokens[rhs2_part..]
                rhs = OpNode.new op, [rhs, rhs2]
            end
            final.operands << rhs
            { final, total }
        end

        def self.parse_op(tokens)
            total = 0
            unless lhs = self.parse_term tokens
                return nil
            end
            lhs, lhs_part = lhs
            total += lhs_part
            tokens = tokens[lhs_part..]
            unless self.expect tokens, Tag::L1op
                return { lhs, total }
            end
            op = tokens[0][0]
            total += 1
            tokens = tokens[1..]
            unless rhs = self.parse_term tokens
                return nil
            end
            rhs, rhs_part = rhs
            total += rhs_part
            tokens = tokens[rhs_part..]
            final = OpNode.new op, [lhs]
            while self.expect tokens, Tag::L1op
                op = tokens[0][0]
                total += 1
                tokens = tokens[1..]
                unless rhs2 = self.parse_term tokens
                    return nil
                end
                rhs2, rhs2_part = rhs2
                total += rhs2_part
                tokens = tokens[rhs2_part..]
                rhs = OpNode.new op, [rhs, rhs2]
            end
            final.operands << rhs
            { final, total }
        end

        def self.parse_fn(tokens : Array(Token))
            unless self.expect tokens, Tag::Fn
                return nil
            end
            total = 1
            tokens = tokens[1..]
            unless name = self.expect tokens, Tag::Name
                return nil
            end
            total += 1
            tokens = tokens[1..]
            unless args = self.get_sequence tokens, Tag::Lpar, Tag::Rpar do |tokens|
                    self.parse_name tokens
                end
                return nil
            end
            args, args_part = args
            total += args_part
            tokens = tokens[args_part..]
            unless body = self.parse_expr tokens
                return nil
            end
            body, body_part = body
            total += body_part
            { FnNode.new(name, args, body), total }
        end

        def self.parse_object(tokens : Array(Token))
            unless self.expect tokens, Tag::Object
                return nil
            end
            total = 1
            tokens = tokens[1..]
            unless name = self.expect tokens, Tag::Name
                return nil
            end
            total += 1
            tokens = tokens[1..]
            unless args = self.get_sequence tokens, Tag::Lpar, Tag::Rpar do |tokens|
                    self.parse_name tokens
                end
                unless body = self.parse_expr tokens
                    return nil
                end
                body, body_part = body
                total += body_part
                return { ObjectNode.new(name, nil, body), total }
            end
            args, args_part = args.as { Array(Node), Int32 }
            total += args_part
            tokens = tokens[args_part..]
            unless body = self.parse_expr tokens
                return nil
            end
            body, body_part = body
            total += body_part
            { ObjectNode.new(name, args, body), total }
        end

        def self.parse_expr(tokens : Array(Token))
            if self.expect tokens, Tag::Lpar
                tokens = tokens[1..]
                unless expr = self.parse_expr tokens
                    return nil
                end
                expr, expr_part = expr
                tokens = tokens[expr_part..]
                unless self.expect tokens, Tag::Rpar
                    return nil
                end
                { expr, expr_part + 2 }
            else
                self.parse_require(tokens) ||
                self.parse_object(tokens) ||
                self.parse_fn(tokens) ||
                self.parse_op(tokens) ||
                self.parse_for(tokens) ||
                self.parse_while(tokens) ||
                self.parse_if(tokens) ||
                self.parse_new(tokens) ||
                self.parse_call(tokens) ||
                self.parse_assign(tokens) ||
                self.parse_index(tokens) ||
                self.parse_access(tokens) ||
                self.parse_literal(tokens)
            end
        end

        def self.parse_require(tokens : Array(Token))
            unless self.expect tokens, Tag::Require
                return nil
            end
            tokens = tokens[1..]

            unless path = self.expect tokens, Tag::Str
                return nil
            end
            path = path[1..-2]
            { RequireNode.new(path), 2 }
        end

        def self.parse(code : String)
            tokens = Lexer.lex code
            if tokens
                parsed = [] of Node
                while tokens.size > 0
                    unless expr = self.parse_expr tokens
                        Error.parser_error "Expected expression"
                        return nil
                    end
                    expr, part = expr.as { Node, Int32 }
                    case expr
                    when RequireNode
                        path = Lookup.lookup expr.path
                        if path
                            code2 = File.read path
                            lexed2 = Lexer.lex(code2)
                            if lexed2
                                tokens = lexed2 + tokens[part..]
                            else
                                return nil
                            end
                        else
                            return nil
                        end
                    else
                        parsed << expr
                        tokens = tokens[part..]
                    end
                end
                parsed
            end
        end
    end
end