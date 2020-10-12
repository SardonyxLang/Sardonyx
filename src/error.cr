module SDX
    class Error
        @@callstack = [] of String
        @@no_exit = false

        def self.enter_call(call : String)
            @@callstack << call
        end

        def self.no_exit=(val : Bool)
            @@no_exit = val
        end

        def self.leave_call
            @@callstack.pop
        end

        def self.backtrace
            @@callstack.reverse.each do |item|
                STDERR.puts "  \e[31mIn #{item}"
            end
            STDERR.print "\e[0m"
        end

        def self.error(type : String, msg : String)
            STDERR.puts "\e[31m#{type} error: #{msg}\e[0m"
            self.backtrace
            unless @@no_exit
                exit 1
            end
        end

        def self.lexer_error(msg : String)
            self.error "Lexer", msg
        end

        def self.parser_error(msg : String)
            self.error "Parser", msg
        end

        def self.lookup_error(msg : String)
            self.error "Lookup", msg
        end

        def self.vm_error(msg : String)
            self.error "VM", msg
        end

        def self.type_error(msg : String)
            self.error "Type", msg
        end

        def self.list_error(msg : String)
            self.error "List", msg
        end

        def self.cli_error(msg : String)
            self.error "CLI", msg
        end
    end
end