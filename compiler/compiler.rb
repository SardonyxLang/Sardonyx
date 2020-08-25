module Compiler
    class Compiler
        def self.compile(ast)
            bc = ""
            ast.each do |line|
                bc += self.encode_node line
            end
            bc + "\x16"
        end

        def self.encode_block(node)
            bc = ""
            node.children.each do |child|
                bc += self.encode_node child
            end
            bc
        end

        def self.encode_node(node)
            bc = ""
            case node.nodetype
            when :assign
                name = node.children[0]
                val = node.children[1]
                case node.value
                when "=" # could also be +=, -=, etc.
                    bc += "#{self.encode_node val}\x01\x10#{name}\x18"
                else
                    nil
                end
            when :number
                bc += "\x21\x13#{node.value}\x18"
            when :float
                bc += "\x21\x15#{node.value}\x18"
            when :string
                bc += "\x21\x14#{node.value}\x18"
            when :call
                node.children.each do |item|
                    bc += self.encode_node item
                end
                bc += self.encode_node node.value
                bc += "\x02"
            when :new
                node.children.each do |item|
                    bc += self.encode_node item
                end
                bc += self.encode_node node.value
                bc += "\x31"
            when :op
                node.children.each do |child|
                    bc += self.encode_node child
                end
                case node.value
                when "+"
                    bc += "\x23"
                when "-"
                    bc += "\x24"
                when "*"
                    bc += "\x25"
                when "/"
                    bc += "\x26"
                when "%"
                    bc += "\x27"
                when "^"
                    bc += "\x28"
                end
            when :if
                bc += self.encode_node node.value
                case node.children[0].nodetype
                when :block
                    i = self.encode_block node.children[0]
                else
                    i = self.encode_node node.children[0]
                end
                e = nil
                if node.children[1]
                    case node.children[1].nodetype
                        when :block
                        e = self.encode_block node.children[1]
                    else
                        e = self.encode_node node.children[1]
                    end
                    i += "\x2a#{e.size}\x18"
                end
                bc += "\x29#{i.size}\x18" + i
                if e
                    bc += e
                end
            when :name
                bc += "\x20#{node.value}\x18"
            when :nil
                bc += "\x21\x2f"
            when :while
                e = self.encode_node node.value
                bc += e
                total = e.size
                b = nil
                case node.children[0].nodetype
                when :block
                    b = self.encode_block node.children[0]
                else
                    b = self.encode_node node.children[0]
                end
                add = ""
                #bc += "\x2b#{b.size}\x18"
                total += "\x29#{b.size}\x18".size
                add += b
                total += b.size
                total += "\x2a-#{total}\x18".size
                add += "\x2a-#{total}\x18"
                total -= "\x29#{b.size}\x18".size
                total -= e.size
                add = "\x2b#{total}\x18" + add
                bc += add
            when :for
                bc += self.encode_node node.value
                sym = (0...8).map { (65 + rand(26)).chr }.join
                bc += "\x01\x10__#{sym}\x18"
                e = "\x20__#{sym}\x18\x2e"
                if node.children[0]
                    e += "\x01\x10#{node.children[0]}\x18"
                else
                    e += "\x01\x10_\x18"
                end
                bc += e
                total = e.size
                b = nil
                case node.children[1].nodetype
                when :block
                    b = self.encode_block node.children[1]
                else
                    b = self.encode_node node.children[1]
                end
                add = ""
                total += "\x29#{b.size}\x18".size
                add += b
                total += b.size
                total += "\x2a-#{total}\x18".size
                add += "\x2a-#{total}\x18"
                total -= "\x29#{b.size}\x18".size
                total -= e.size
                add = "\x2b#{total}\x18" + add
                bc += add
            when :fn
                name = node.value
                args, body = node.children
                if body.nodetype == :block
                    body = self.encode_block body
                else
                    body = self.encode_node body
                end
                body += "\x16"
                args = args.join "\x07"
                bc += "\x01\x17#{name}\x18#{args}\x08#{body.size}\x18"
                bc += body
            when :object
                name = node.value
                args, body = node.children
                if body.nodetype == :block
                    body = self.encode_block body
                else
                    body = self.encode_node body
                end
                body += "\x16"
                if args
                    args = args.join "\x07"
                else
                    args = ""
                end
                bc += "\x01\x30#{name}\x18#{args}\x08#{body.size}\x18"
                bc += body
            when :list
                node.children.each do |item|
                    bc += self.encode_node item
                end
                bc += "\x21\x2c#{node.children.size}\x18"
            else
                nil
            end
            bc
        end
    end
end