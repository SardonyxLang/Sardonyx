require "./vm/vm"
require "./vm/variables"
require "stringio"

class DataType 
    attr_reader :internal
    attr_reader :fields

    @fields
    def initialize(val=nil) 
        @internal = val
        @fields = {}
    end
end

class NativeFnInternal
    attr_reader :arity

    def initialize(val=nil)
        @internal = val
        @arity = IntInternal.new val.arity
    end

    def call(*args)
        @internal.call *args
    end
end

class IntInternal < DataType
    def initialize(val)
        @internal = val
    end
end

class NativeFn < DataType
    def initialize(arity, val)
        @internal = val
        @fields = {
            "__call" => (NativeFnInternal.new (Proc.new do |args|
                args.reverse!
                @internal.call *args
            end)),
            "__arity" => (Int.new arity)
        }
    end
end

class Bool < DataType
    def initialize(val=nil)
        if val
            @internal = true
        else
            @internal = false
        end
        @fields = {
            "__as_string" => (NativeFn.new 0, (Proc.new do
                as_string
            end)),
            "__as_code_string" => (NativeFn.new 0, (Proc.new do
                as_string
            end))
        }
    end

    def as_string
        Str.new ({ true => "true", false => "false" }[@internal])
    end
end

class Int < DataType
    def initialize(val=nil)
        if val != nil
            @internal = val
        end
        @fields = {
            "__as_string" => (NativeFnInternal.new (Proc.new do
                as_string
            end)),
            "__as_code_string" => (NativeFnInternal.new (Proc.new do
                as_string
            end)),
            "__as_bool" => (NativeFnInternal.new (Proc.new do
                as_bool
            end)),
            "__add" => (NativeFnInternal.new (Proc.new do |other|
                add other
            end)),
            "__sub" => (NativeFnInternal.new (Proc.new do |other|
                sub other
            end)),
            "__mul" => (NativeFnInternal.new (Proc.new do |other|
                mul other
            end)),
            "__div" => (NativeFnInternal.new (Proc.new do |other|
                div other
            end)),
            "__mod" => (NativeFnInternal.new (Proc.new do |other|
                mod other
            end)),
            "__pow" => (NativeFnInternal.new (Proc.new do |other|
                pow other
            end))
        }
    end

    def as_string
        Str.new @internal.to_s
    end

    def as_bool
        Bool.new true
    end

    def add(other)
        Int.new @internal + other.internal
    end

    def sub(other)
        Int.new @internal - other.internal
    end

    def mul(other)
        Int.new @internal * other.internal
    end

    def div(other)
        Int.new @internal / other.internal
    end

    def mod(other)
        Int.new @internal % other.internal
    end

    def pow(other)
        Int.new @internal ** other.internal
    end
end

class Str < DataType 
    def initialize(val=nil)
        if val != nil
            @internal = val
        end
        @fields = {
            "__as_string" => (NativeFnInternal.new (Proc.new do 
                as_string
            end)),
            "__as_code_string" => (NativeFnInternal.new (Proc.new do
                as_code_string
            end)),
            "__add" => (NativeFnInternal.new (Proc.new do |other|
                add other
            end)),
            "__mul" => (NativeFnInternal.new (Proc.new do |other|
                mul other
            end))
        }
    end

    def as_string
        (Str.new @internal)
    end

    def as_code_string
        (Str.new "\"#{@internal}\"")
    end

    def add(other)
        Str.new @internal + other.internal
    end

    def mul(other)
        Str.new @internal * other.internal
    end
end

class Num < DataType
    def initialize(val=nil)
        if val != nil
            @internal = val
        end
        @fields = {
            "__as_string" => (NativeFnInternal.new (Proc.new do
                as_string
            end)),
            "__as_code_string" => (NativeFnInternal.new (Proc.new do
                as_string
            end)),
            "__as_bool" => (NativeFnInternal.new (Proc.new do
                as_bool
            end)),
            "__add" => (NativeFnInternal.new (Proc.new do |other|
                add other
            end)),
            "__sub" => (NativeFnInternal.new (Proc.new do |other|
                sub other
            end)),
            "__mul" => (NativeFnInternal.new (Proc.new do |other|
                mul other
            end)),
            "__div" => (NativeFnInternal.new (Proc.new do |other|
                div other
            end)),
            "__mod" => (NativeFnInternal.new (Proc.new do |other|
                mod other
            end)),
            "__pow" => (NativeFnInternal.new (Proc.new do |other|
                pow other
            end))
        }
    end

    def as_string
        Str.new @internal.to_s
    end

    def as_bool
        Bool.new true
    end

    def add(other)
        Num.new @internal + other.internal
    end

    def sub(other)
        Num.new @internal - other.internal
    end

    def mul(other)
        Num.new @internal * other.internal
    end

    def div(other)
        Num.new @internal / other.internal
    end

    def mod(other)
        Num.new @internal % other.internal
    end

    def pow(other)
        Num.new @internal ** other.internal
    end
end

class Nil < DataType
    def initialize
        @internal = nil
        @fields = {
            "__as_bool" => (NativeFnInternal.new (Proc.new do
                Bool.new false
            end))
        }
    end
end

class List < DataType
    def initialize(val)
        @internal = val
        @pos = 0
        @fields = {
            "__as_string" => (NativeFnInternal.new (Proc.new do 
                as_string
            end)),
            "__as_code_string" => (NativeFnInternal.new (Proc.new do
                as_code_string
            end)),
            "__reset" => (NativeFnInternal.new (Proc.new do 
                reset
            end)),
            "__iter" => (NativeFnInternal.new (Proc.new do 
                iter
            end)),
            "__add" => (NativeFnInternal.new (Proc.new do |other|
                add other
            end)),
            "__mul" => (NativeFnInternal.new (Proc.new do |other|
                mul other
            end))
        }
    end

    def as_string
        s = "["
        @internal.each do |item|
            s += (stringify item) + ", "
        end
        s = s[0..-3]
        s += "]"
        Str.new s
    end

    def as_code_string
        s = "["
        @internal.each do |item|
            s += (codify item) + ", "
        end
        s = s[0..-3]
        s += "]"
        Str.new s
    end

    def reset
        @pos = 0
    end

    def iter
        val = @internal[@pos]
        @pos += 1
        if val
            return val
        else
            return Variable.new Nil.new
        end
    end
    
    def add(other)
        return List.new [*@internal, other]
    end

    def mul(other)
        return List.new @internal * other.internal
    end
end

def get_type(x)
    case x
    when Int
        :int
    when Str
        :str
    when Bool
        :bool
    when Function
        :fn
    when List
        :list
    when Nil
        :nil
    when Num
        :num
    when Obj
        :object
    end
end

class Function < DataType
    attr_reader :args

    def initialize(args, body)
        @args = args
        @internal = body

        @fields = {
            "__call" => (NativeFnInternal.new (Proc.new do |args, scope|
                call args, scope
            end)),
            "__arity" => (Int.new args.size)
        }
    end

    def call(passed, scope)
        passed.reverse!
        vm = VM.new StringIO.new @internal
        scope.variables.each do |k|
            vm.global.add_var k[0], (scope.get_var k[0])
        end
        args.each_with_index do |arg, i|
            vm.global.add_var arg, passed[i]
        end
        vm.interpret
        vm.stack[-1]
    end
end

class Obj < DataType
    attr_reader :args

    def initialize(args, body)
        @args = args
        @internal = body

        @fields = {
            "__new" => (NativeFnInternal.new (Proc.new do |args, scope|
                _new args, scope
            end)),
            "__arity" => (Int.new args.size)
        }
    end

    def _new(passed, scope)
        passed.reverse!
        vm = VM.new StringIO.new @internal
        scope.variables.each do |k|
            vm.global.add_var k[0], (scope.get_var k[0])
        end
        args.each_with_index do |arg, i|
            vm.global.add_var arg, passed[i]
        end
        vm.interpret
        vm.global
    end
end

class InstantiatedObj < DataType
    def initialize(scope)
        @internal = scope
        @fields = scope.variables
    end
end