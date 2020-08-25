require './vm/variables'
require './vm/datatypes'
require './vm/scope'

def stringify(val)
    if val.value.fields["__as_string"]
        (val.value.fields["__as_string"].call).internal
    else
        val.value.to_s
    end
end

def codify(val)
    if val.value.fields["__as_code_string"]
        (val.value.fields["__as_code_string"].call).internal
    else
        val.value.pretty_inspect
    end
end

def truthy(val)
    if val.value.fields["__as_bool"]
        (val.value.fields["__as_bool"].call).internal
    else
        true
    end
end

class VM
    attr_accessor :bc_io

    def initialize(bc_io) 
        @bc_io = bc_io 
        @global = GLOBAL_SCOPE.new
        @global.add_fn "__rb_call", (Variable.new (NativeFn.new 2, (Proc.new do |name, args|
            args = (codify args)[1..-2]
            eval "#{name.value.internal}(#{args})"
        end)), @global)
        @stack = []
        @byte_pos = 0
    end


    def global
        @global
    end

    def byte_pos=(n)
        @byte_pos = n
    end
   
    def load_bytes(x_bytes, to_symbol=true) # loads in next x bytes from file, returns in array
        insts = { # just a simple hash to make interpreter code more readable 
            0x01 => :make,
            0x02 => :call,
            0x03 => :return,
            0x04 => :set,
            0x05 => :mut,
            0x06 => :exec,
            0x10 => :var,
            0x16 => :end_prg,
            0x17 => :fn,
            0x18 => :strend,
            0x21 => :const,
            0x23 => :add,
            0x24 => :sub,
            0x25 => :mul,
            0x26 => :div,
            0x12 => :bool,
            0x13 => :int,
            0x14 => :str,
            0x15 => :num,
            0x29 => :jmpi,
            0x2a => :jmp,
            0x2b => :jmpn,
            0x20 => :get,
            0x2c => :list,
            0x2f => :nil,
            0x2d => :reset,
            0x2e => :iter,
            0x30 => :object,
            0x31 => :new
        }
        bytes = []
        begin
            x_bytes.times do
                @bc_io.seek(@byte_pos)
                byte_integer = @bc_io.sysread(1).ord
                bytes.push(to_symbol ? insts[byte_integer] : byte_integer)
                @byte_pos += 1
            end
            # add rescue here eventually (mainly to handle end of file error)
        end
        bytes
    end

    def get_string # when called, gets all bytes until STREND and returns them as string
        string = ""
        while (byte = load_bytes(1, false)[0]) != 24 # cant use STREND here, need byte as is
            string += byte.chr 
        end
        string
    end

    def get_args
        args = []
        this = ""
        while (byte = load_bytes(1, false)[0]) != 0x08
            if byte == 0x07
                args << this
                this = ""
            else
                this += byte.chr
            end
        end
        if this != ""
            args << this
        end
        args
    end

    def push_to_stack(to_push)
        @stack.push to_push
    end

    def pop_from_stack
        @stack.pop
    end

    def stack
        @stack
    end

    def error(msg)
        puts "\x1b[0;31mError in VM: #{msg}\x1b[0;0m"
        exit 1
    end

    def interpret # builds stack from bytecode
        loop do  
            loaded_bytes = load_bytes(1) # loads in first byte for initial instruction
            break if loaded_bytes[0] == :end_prg # end of program reached 

            case loaded_bytes[0]
            when :make
                loaded_bytes.concat load_bytes(1) 
                case loaded_bytes[1]
                when :var
                    var_name = get_string
                    val = pop_from_stack
                    @global.add_var var_name, val
                    push_to_stack val # assignments evaluate to their value
                when :fn 
                    # make fn <name> 
                    fn_name = get_string
                    args = get_args
                    size = get_string.to_i
                    body = 
                        ((load_bytes size, false).map { |e| e.chr }).join ""
                    fn = Function.new args, body
                    @global.add_fn fn_name, (Variable.new fn, :fn, @global)
                when :object
                    # make fn <name> 
                    obj_name = get_string
                    args = get_args
                    size = get_string.to_i
                    body = 
                        ((load_bytes size, false).map { |e| e.chr }).join ""
                    obj = Obj.new args, body
                    @global.add_obj obj_name, (Variable.new obj, :obj, @global)
                end
            when :set
                var_name = get_string
                val = pop_from_stack
                @global.add_var var_name, val
                push_to_stack val # assignments evaluate to their value
            when :const
                loaded_bytes.concat load_bytes(1)
                case loaded_bytes[1]
                when :int
                    val = get_string
                    push_to_stack Variable.new (Int.new val.to_i), :int, @global
                when :str
                    val = get_string
                    push_to_stack Variable.new (Str.new val), :str, @global
                when :list
                    count = get_string.to_i
                    vals = []
                    count.times do
                        vals << pop_from_stack
                    end
                    vals.reverse!
                    push_to_stack Variable.new (List.new vals), :list, @global
                when :nil
                    push_to_stack Variable.new (Nil.new), :nil, @global
                end
            when :add
                b, a = pop_from_stack, pop_from_stack
                if a.value.fields["__add"]
                    res = (a.value.fields["__add"].call b.value)
                    push_to_stack (Variable.new res, (get_type res), @global) 
                else
                    error "Cannot add to #{a.type}"
                end
            when :sub
                b, a = pop_from_stack, pop_from_stack
                if a.value.fields["__sub"]
                    res = (a.value.fields["__sub"].call b.value)
                    push_to_stack (Variable.new res, (get_type res), @global) 
                else
                    error "Cannot subtract from #{a.type}"
                end
            when :mul
                b, a = pop_from_stack, pop_from_stack
                if a.value.fields["__mul"]
                    res = (a.value.fields["__mul"].call b.value)
                    push_to_stack (Variable.new res, (get_type res), @global) 
                else
                    error "Cannot multiply #{a.type}"
                end
            when :div
                b, a = pop_from_stack, pop_from_stack
                if a.value.fields["__div"]
                    res = (a.value.fields["__div"].call b.value)
                    push_to_stack (Variable.new res, (get_type res), @global) 
                else
                    error "Cannot divide #{a.type}"
                end
            when :mod
                b, a = pop_from_stack, pop_from_stack
                if a.value.fields["__mod"]
                    res = (a.value.fields["__mod"].call b.value)
                    push_to_stack (Variable.new res, (get_type res), @global) 
                else
                    error "Cannot modulo #{a.type}"
                end
            when :pow
                b, a = pop_from_stack, pop_from_stack
                if a.value.fields["__pow"]
                    res = (a.value.fields["__pow"].call b.value)
                    push_to_stack (Variable.new res, (get_type res), @global) 
                else
                    error "Cannot exponentiate #{a.type}"
                end
            when :jmpi
                val = pop_from_stack
                amt = get_string
                if truthy val
                    @byte_pos += amt.to_i
                end
            when :jmpn
                val = pop_from_stack
                amt = get_string
                unless truthy val
                    @byte_pos += amt.to_i
                end
            when :jmp
                amt = get_string
                @byte_pos += amt.to_i
            when :get
                name = get_string
                var = @global.get_var name
                if var
                    push_to_stack var
                else
                    error "No such variable #{name}"
                end
            when :reset
                val = pop_from_stack
                if val.value.fields["__reset"]
                    val.value.fields["__reset"].call
                    push_to_stack val
                end
            when :iter
                val = pop_from_stack
                if val.value.fields["__iter"]
                    res = val.value.fields["__iter"].call
                    push_to_stack res
                end
            when :call
                val = pop_from_stack
                if val.value.fields["__call"] and val.value.fields["__arity"]
                    args = []
                    val.value.fields["__arity"].internal.times do
                        this = pop_from_stack
                        unless this
                            error "Not enough arguments: expected #{val.value.fields["__arity"].internal}, got #{args.size}"
                        end
                        args << this
                    end
                    f = Proc.new do |args, scope|
                        val.value.fields["__call"].call args, scope
                    end
                    scope = nil
                    begin
                        scope = val.scope
                    rescue
                        scope = @global
                    end
                    ret = f.call args, scope
                    if ret
                        push_to_stack ret
                    end
                else
                    error "Cannot call #{stringify val}"
                end
            when :new
                val = pop_from_stack
                if val.value.fields["__new"] and val.value.fields["__arity"]
                    args = []
                    val.value.fields["__arity"].internal.times do
                        this = pop_from_stack
                        unless this
                            error "Not enough arguments: expected #{val.value.fields["__arity"].internal}, got #{args.size}"
                        end
                        args << this
                    end
                    f = Proc.new do |args, scope|
                        val.value.fields["__new"].call args, scope
                    end
                    ret = Variable.new (InstantiatedObj.new f.call args, @global), @global
                    if ret
                        push_to_stack ret
                    end
                else
                    error "Cannot instantiate #{stringify val}"
                end
            end
        end
    end
end

