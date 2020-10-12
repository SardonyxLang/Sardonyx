require "./parser"

module SDX
    class Compiler
        def self.encode_str(s : String, bc : String::Builder)
            bc.write_bytes s.size, IO::ByteFormat::LittleEndian
            bc << s
        end

        def self.encode_node(node : Parser::Node, bc : String::Builder)
            case node
            when Parser::IntNode
                value = node.value.to_i
                bc << "\x02\x01" # const int
                bc.write_bytes value, IO::ByteFormat::LittleEndian
            when Parser::StrNode
                bc << "\x02\x02" # const str
                self.encode_str node.value[1..-2], bc
            when Parser::BoolNode
                bc << "\x02\x03" # const bool
                bc << (node.value == "true" ? "\x01" : "\x00")
            when Parser::NumNode
                bc << "\x02\x04" # const num
                self.encode_str node.value, bc
            when Parser::NilNode
                bc << "\x02\x05" # const nil
            when Parser::AssignNode
                self.encode_node node.value, bc
                bc << "\x01\x01" # make var
                self.encode_str node.name, bc
            when Parser::NameNode
                bc << "\x03" # get
                self.encode_str node.value, bc
            when Parser::ListNode
                node.children.each do |node|
                    self.encode_node node, bc
                end
                bc << "\x02\x06"
                bc.write_bytes node.children.size, IO::ByteFormat::LittleEndian
            when Parser::OpNode
                node.operands.each do |node|
                    self.encode_node node, bc
                end
                case node.op
                when "+"
                    bc << "\x04"
                when "-"
                    bc << "\x05"
                when "*"
                    bc << "\x06"
                when "/"
                    bc << "\x07"
                when "%"
                    bc << "\x08"
                when "^"
                    bc << "\x09"
                when "<"
                    bc << "\x0a"
                when ">"
                    bc << "\x0b"
                when "<="
                    bc << "\x0c"
                when ">="
                    bc << "\x0d"
                when "=="
                    bc << "\x0e"
                when "!="
                    bc << "\x0f"
                end
            when Parser::CallNode
                node.children.reverse.each do |child|
                    self.encode_node child, bc
                end
                self.encode_node node.value, bc
                bc << "\x10"
                bc.write_bytes node.children.size, IO::ByteFormat::LittleEndian
            when Parser::IfNode
                self.encode_node node.cond, bc
                other = String.build do |bc|
                    if node.other
                        o = node.other.as Parser::Node
                        case o
                        when Parser::BlockNode
                            o.children.each do |child|
                                self.encode_node child, bc
                            end
                        else
                            self.encode_node o, bc
                        end
                    end
                end
                body = String.build do |bc|
                    case node.body
                    when Parser::BlockNode
                        node.body.children.each do |child|
                            self.encode_node child, bc
                        end
                    else
                        self.encode_node node.body, bc
                    end
                    bc << "\x13"
                    bc.write_bytes other.size, IO::ByteFormat::LittleEndian
                end
                bc << "\x12"
                bc.write_bytes body.size, IO::ByteFormat::LittleEndian
                bc << body
                bc << other
            when Parser::WhileNode
                cond = String.build do |bc|
                    self.encode_node node.cond, bc
                end
                body = String.build do |bc|
                    nested = String.build do |bc|
                        case node.body
                        when Parser::BlockNode
                            node.body.children.each do |child|
                                self.encode_node child, bc
                            end
                        else
                            self.encode_node node.body, bc
                        end
                    end
                    bc << nested
                    bc << "\x13"
                    bc.write_bytes -(cond.size + nested.size + 5), IO::ByteFormat::LittleEndian
                end
                bc << cond
                bc << "\x12"
                bc.write_bytes body.size, IO::ByteFormat::LittleEndian
                bc << body
            when Parser::ForNode
                cond = String.build do |bc|
                    self.encode_node node.value, bc
                    self.encode_node node.value, bc
                    bc << "\x15"
                    bc << "\x16"
                end
                body = String.build do |bc|
                    nested = String.build do |bc|
                        bc << "\x17"
                        bc << "\x01\x01"
                        self.encode_str (node.name || "_"), bc
                        case node.body
                        when Parser::BlockNode
                            node.body.children.each do |child|
                                self.encode_node child, bc
                            end
                        else
                            self.encode_node node.body, bc
                        end
                    end
                    bc << nested
                    bc << "\x13"
                    bc.write_bytes -(cond.size + nested.size + 5), IO::ByteFormat::LittleEndian
                end
                bc << cond
                bc << "\x11"
                bc.write_bytes body.size, IO::ByteFormat::LittleEndian
                bc << body
            when Parser::IndexNode
                self.encode_node node.value, bc
                self.encode_node node.index, bc
                bc << "\x14"
            when Parser::FnNode
                bc << "\x02\x07"
                bc.write_bytes node.args.size, IO::ByteFormat::LittleEndian
                node.args.each do |arg|
                    arg = arg.as Parser::NameNode
                    self.encode_str arg.value, bc
                end
                body = String.build do |bc|
                    case node.body
                    when Parser::BlockNode
                        node.body.children.each do |child|
                            self.encode_node child, bc
                        end
                    else
                        self.encode_node node.body, bc
                    end
                    bc << "\x00"
                end
                self.encode_str body, bc
                bc << "\x01\x02"
                self.encode_str node.name, bc
            when Parser::ObjectNode
                bc << "\x01\x03"
                self.encode_str node.name, bc
                if node.args.nil?
                    bc.write_bytes 0, IO::ByteFormat::LittleEndian
                else
                    args = node.args.as Array(Parser::Node)
                    bc.write_bytes args.size, IO::ByteFormat::LittleEndian
                    args.each do |arg|
                        arg = arg.as Parser::NameNode
                        self.encode_str arg.value, bc
                    end
                end
                body = String.build do |bc|
                    case node.body
                    when Parser::BlockNode
                        node.body.children.each do |child|
                            self.encode_node child, bc
                        end
                    else
                        self.encode_node node.body, bc
                    end
                    bc << "\x00"
                end
                self.encode_str body, bc
            when Parser::AccessNode
                self.encode_node node.value, bc
                node.fields.each do |name|
                    bc << "\x18"
                    self.encode_str name, bc
                end
            when Parser::NewNode
                node.children.reverse.each do |child|
                    self.encode_node child, bc
                end
                self.encode_node node.value, bc
                bc << "\x19"
                bc.write_bytes node.children.size, IO::ByteFormat::LittleEndian
            when Parser::BlockNode
                body = String.build do |bc|
                    node.children.each do |child|
                        self.encode_node child, bc
                    end
                    bc << "\x00"
                end
                bc << "\x02\x08"
                self.encode_str body, bc
            end
        end

        def self.compile(ast : Array(Parser::Node), clear = true)
            String.build do |bc|
                ast.each do |node|
                    self.encode_node node, bc
                    bc << "\x20" if clear
                end
                bc << "\x00"
            end
        end
    end
end