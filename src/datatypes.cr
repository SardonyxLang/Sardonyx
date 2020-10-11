require "big/big_decimal.cr"

module SDX
    module Datatypes
        abstract class Value
            getter fields : Hash(String, Value)
            getter scope : Hash(String, Value)
            getter name : String

            def initialize(scope = {} of String => Value, name = "anonymous")
                @fields = {} of String => Value
                @scope = scope
                @name = name
            end

            def assign_to(name : String)
                @name = name
            end
        end

        def self.base_typename(val : Value)
            "#{val.class}".split("::")[-1][3..]
        end
        
        class SDXInternalArityInt < Value
            getter internal : Int32

            def initialize(internal : Int32, scope = {} of String => Value, name = "anonymous")
                @internal = internal
                @fields = {} of String => Value
                @scope = scope
                @name = name
            end
        end

        class SDXNativeFnInternal < Value
            getter internal : Proc(Array(Value), Value?)

            def initialize(
                    internal : Proc(Array(Value), Value?), 
                    scope = {} of String => Value,
                    name = "anonymous"
                )
                @internal = internal
                @fields = {} of String => Value
                @scope = scope
                @name = name
            end
        end

        class SDXNativeFn < Value
            getter internal : Nil

            def initialize(
                internal : Proc(Array(Value), Value?),
                arity : Int32,
                scope = {} of String => Value,
                name = "anonymous"
            )
                @fields = {
                    "__arity" => SDXInternalArityInt.new(arity),
                    "__call" => SDXNativeFnInternal.new(internal)
                }
                @internal = nil
                @scope = scope
                @name = name
            end
        end

        abstract class ArithmeticValue(T) < Value
            getter internal : T
            getter scope : Hash(String, Value)
            getter fields : Hash(String, Value)

            def initialize
                super()
                @internal = T.new 0
                @scope = {} of String => Value
                @fields = {
                    "__add" => SDXNativeFn.new(Proc(Array(Value), Value?).new do |args|
                        case args[0]
                        when ArithmeticValue
                            val = args[0].as self
                            return self.class.new @internal + val.internal    
                        else
                            Error.type_error "Cannot add #{Datatypes.base_typename self} and #{Datatypes.base_typename args[0]}"
                            return nil
                        end
                    end, 1, scope),
                    "__sub" => SDXNativeFn.new(Proc(Array(Value), Value?).new do |args|
                        case args[0]
                        when ArithmeticValue
                            val = args[0].as self
                            return self.class.new @internal - val.internal    
                        else
                            Error.type_error "Cannot subtract #{Datatypes.base_typename self} and #{Datatypes.base_typename args[0]}"
                            return nil
                        end
                    end, 1, scope),
                    "__mul" => SDXNativeFn.new(Proc(Array(Value), Value?).new do |args|
                        case args[0]
                        when ArithmeticValue
                            val = args[0].as self
                            return self.class.new @internal * val.internal    
                        else
                            Error.type_error "Cannot multiply #{Datatypes.base_typename self} and #{Datatypes.base_typename args[0]}"
                            return nil
                        end
                    end, 1, scope),
                    "__div" => SDXNativeFn.new(Proc(Array(Value), Value?).new do |args|
                        case args[0]
                        when ArithmeticValue
                            val = args[0].as self
                            return self.class.new @internal / val.internal 
                        else
                            Error.type_error "Cannot divide #{Datatypes.base_typename self} and #{Datatypes.base_typename args[0]}"
                            return nil
                        end
                    end, 1, scope),
                    "__pow" => SDXNativeFn.new(Proc(Array(Value), Value?).new do |args|
                        case args[0]
                        when ArithmeticValue
                            val = args[0].as self
                            return self.class.new @internal ** val.internal    
                        else
                            Error.type_error "Cannot exponentiate #{Datatypes.base_typename self} and #{Datatypes.base_typename args[0]}"
                            return nil
                        end
                    end, 1, scope),
                    "__mod" => SDXNativeFn.new(Proc(Array(Value), Value?).new do |args|
                        case args[0]
                        when ArithmeticValue
                            val = args[0].as self
                            return self.class.new @internal % val.internal    
                        else
                            Error.type_error "Cannot modulo #{Datatypes.base_typename self} and #{Datatypes.base_typename args[0]}"
                            return nil
                        end
                    end, 1, scope),
                    "__lt" => SDXNativeFn.new(Proc(Array(Value), Value?).new do |args|
                        case args[0]
                        when ArithmeticValue
                            arg = args[0].as ArithmeticValue
                            return SDXBool.new @internal < arg.internal, @scope
                        else
                            Error.type_error "Cannot compare #{Datatypes.base_typename self} and #{Datatypes.base_typename args[0]}"
                            return nil
                        end
                    end, 1, scope),
                    "__gt" => SDXNativeFn.new(Proc(Array(Value), Value?).new do |args|
                        case args[0]
                        when ArithmeticValue
                            arg = args[0].as ArithmeticValue
                            return SDXBool.new @internal > arg.internal, @scope
                        else
                            Error.type_error "Cannot compare #{Datatypes.base_typename self} and #{Datatypes.base_typename args[0]}"
                            return nil
                        end
                    end, 1, scope),
                    "__le" => SDXNativeFn.new(Proc(Array(Value), Value?).new do |args|
                        case args[0]
                        when ArithmeticValue
                            arg = args[0].as ArithmeticValue
                            return SDXBool.new @internal <= arg.internal, @scope
                        else
                            Error.type_error "Cannot compare #{Datatypes.base_typename self} and #{Datatypes.base_typename args[0]}"
                            return nil
                        end
                    end, 1, scope),
                    "__ge" => SDXNativeFn.new(Proc(Array(Value), Value?).new do |args|
                        case args[0]
                        when ArithmeticValue
                            arg = args[0].as ArithmeticValue
                            return SDXBool.new @internal >= arg.internal, @scope
                        else
                            Error.type_error "Cannot compare #{Datatypes.base_typename self} and #{Datatypes.base_typename args[0]}"
                            return nil
                        end
                    end, 1, scope)
                } of String => Value
            end
        end

        class SDXInt < ArithmeticValue(Int32)
            def initialize(internal : BigDecimal | Int32 | Float64, scope = {} of String => Value, name = "anonymous")
                super()
                @internal = internal.to_i
                @scope = scope
                @fields.merge!({
                    "__eq" => SDXNativeFn.new(Proc(Array(Value), Value?).new do |args|
                        return SDXBool.new @internal == args[0].internal, @scope
                    end, 1, scope),
                    "__ne" => SDXNativeFn.new(Proc(Array(Value), Value?).new do |args|
                        return SDXBool.new @internal != args[0].internal, @scope
                    end, 1, scope)
                } of String => Value)
                @name = name
            end

            def internal
                @internal
            end
        end

        class SDXStr < Value
            getter internal : String

            def initialize(internal : String, scope = {} of String => Value, name = "anonymous")
                @internal = internal
                @scope = scope
                @fields = {
                    "__eq" => SDXNativeFn.new(Proc(Array(Value), Value?).new do |args|
                        return SDXBool.new @internal == args[0].internal, @scope
                    end, 1, scope),
                    "__ne" => SDXNativeFn.new(Proc(Array(Value), Value?).new do |args|
                        return SDXBool.new @internal != args[0].internal, @scope
                    end, 1, scope)
                } of String => Value
                @name = name
            end
        end

        class SDXBool < Value
            getter internal : Bool

            def initialize(internal : Bool, scope = {} of String => Value, name = "anonymous")
                @internal = internal
                @scope = scope
                @fields = {
                    "__eq" => SDXNativeFn.new(Proc(Array(Value), Value?).new do |args|
                        return SDXBool.new @internal == args[0].internal, @scope
                    end, 1, scope),
                    "__ne" => SDXNativeFn.new(Proc(Array(Value), Value?).new do |args|
                        return SDXBool.new @internal != args[0].internal, @scope
                    end, 1, scope)
                } of String => Value
                @name = name
            end
        end

        class SDXNum < ArithmeticValue(BigDecimal)
            def initialize(internal : BigDecimal | Int32 | Float64, scope = {} of String => Value, name = "anonymous")
                super()
                @internal = BigDecimal.new internal
                @scope = scope
                @fields.merge!({
                    "__eq" => SDXNativeFn.new(Proc(Array(Value), Value?).new do |args|
                        return SDXBool.new @internal == args[0].internal, @scope
                    end, 1, scope),
                    "__ne" => SDXNativeFn.new(Proc(Array(Value), Value?).new do |args|
                        return SDXBool.new @internal != args[0].internal, @scope
                    end, 1, scope)
                } of String => Value)
                @name = name
            end

            def internal
                @internal
            end
        end

        class SDXNil < Value
            getter internal : Nil

            def initialize(scope = {} of String => Value, name = "anonymous")
                @internal = nil
                @scope = scope
                @fields = {
                    "__eq" => SDXNativeFn.new(Proc(Array(Value), Value?).new do |args|
                        return SDXBool.new @internal == args[0].internal, @scope
                    end, 1, scope),
                    "__ne" => SDXNativeFn.new(Proc(Array(Value), Value?).new do |args|
                        return SDXBool.new @internal != args[0].internal, @scope
                    end, 1, scope)
                } of String => Value
                @name = name
            end
        end

        class SDXList < Value
            getter internal : Array(Value)
            @done : Bool
            @pos : Int32
            @current : Value?

            def initialize(internal : Array(Value), scope = {} of String => Value, name = "anonymous", done = false, pos = 0)
                @internal = internal
                @scope = scope
                @done = done
                @name = name
                @pos = pos
                @current = @internal[@pos]?
                @fields = {
                    "__eq" => SDXNativeFn.new(Proc(Array(Value), Value?).new do |args|
                        return SDXBool.new @internal == args[0].internal, @scope
                    end, 1, scope),
                    "__ne" => SDXNativeFn.new(Proc(Array(Value), Value?).new do |args|
                        return SDXBool.new @internal != args[0].internal, @scope
                    end, 1, scope),
                    "__index" => SDXNativeFn.new(Proc(Array(Value), Value?).new do |args|
                        case args[0]
                        when SDXInt
                            arg = args[0].as SDXInt
                            if arg.internal > @internal.size || arg.internal < -@internal.size
                                Error.list_error "Index #{arg.internal} out of range"
                            end
                            return @internal[arg.internal]
                        else
                            Error.type_error "Cannot index List with #{Datatypes.base_typename args[0]}"
                        end
                    end, 1, scope),
                    "__iter" => SDXNativeFn.new(Proc(Array(Value), Value?).new do |args|
                        if @pos < @internal.size
                            @current = @internal[@pos]
                            @pos += 1
                        else
                            @done = true
                        end
                        return SDXList.new @internal, @scope, @name, @done, @pos
                    end, 0, scope),
                    "__done" => SDXNativeFn.new(Proc(Array(Value), Value?).new do |args|
                        SDXBool.new @done, @scope
                    end, 0, scope),
                    "__current" => SDXNativeFn.new(Proc(Array(Value), Value?).new do |args|
                        @current
                    end, 0, scope),
                    "__as_str" => SDXNativeFn.new(Proc(Array(Value), Value?).new do |args|
                        o = "["
                        @internal.each do |item|
                            o += "#{VM.stringify item}, "
                        end
                        o = o[..-3]
                        SDXStr.new(o + "]", @scope)
                    end, 0, scope)
                } of String => Value
            end
        end

        class SDXFn < Value
            getter internal : String

            def initialize(internal : String, args : Array(String), scope = {} of String => Value, name = "anonymous")
                @internal = internal
                @args = args
                @scope = scope
                @name = name
                @fields = {
                    "__call" => SDXNativeFn.new(Proc(Array(Value), Value?).new do |args|
                        vm = VM.new IO::Memory.new(@internal), false
                        vm.scope.merge! @scope
                        @args.each_with_index do |arg, i|
                            vm.scope[arg] = args[i]
                        end
                        vm.run
                        return vm.stack[-1]?
                    end, @args.size, scope),
                    "__arity" => SDXInt.new(@args.size, @scope),
                    "__as_str" => SDXNativeFn.new(Proc(Array(Value), Value?).new do |args|
                        SDXStr.new "Fn<#{@internal.hash}>", @scope
                    end, 1, scope)
                } of String => Value
            end
        end
        
        class SDXBlock < Value
            getter internal : String

            def initialize(internal : String, scope = {} of String => Value, name = "anonymous")
                @internal = internal
                @scope = scope
                @name = name
                @fields = {
                    "__call" => SDXNativeFn.new(Proc(Array(Value), Value?).new do |args|
                        vm = VM.new IO::Memory.new(@internal), false
                        vm.scope.merge! @scope
                        vm.scope["_"] = args[0]
                        vm.run
                        return vm.stack[-1]?
                    end, 1, scope),
                    "__arity" => SDXInt.new(1, @scope),
                    "__as_str" => SDXNativeFn.new(Proc(Array(Value), Value?).new do |args|
                        SDXStr.new "Block<#{@internal.hash}>", @scope
                    end, 1, scope)
                } of String => Value
            end
        end

        class SDXObject < Value
            getter internal : String

            def initialize(internal : String, args : Array(String), scope = {} of String => Value, name = "anonymous")
                @internal = internal
                @args = args
                @scope = scope
                @name = name
                @fields = {
                    "__new" => SDXNativeFn.new(Proc(Array(Value), Value?).new do |args|
                        vm = VM.new IO::Memory.new(@internal), false, @name + ":"
                        vm.scope.merge! @scope
                        @args.each_with_index do |arg, i|
                            vm.scope[arg] = args[i]
                        end
                        vm.run
                        return SDXInstance.new vm.scope, @scope, @name
                    end, @args.size, scope),
                    "__new_arity" => SDXInt.new(@args.size, @scope),
                    "__as_str" => SDXNativeFn.new(Proc(Array(Value), Value?).new do |args|
                        SDXStr.new "Object<#{@internal.hash}>", @scope
                    end, 1, scope)
                } of String => Value
            end
        end

        class SDXInstance < Value
            getter internal : Nil

            def initialize(fields : Hash(String, Value), scope = {} of String => Value, name = "anonymous")
                @internal = nil
                @fields = fields
                @scope = scope
                @name = name
            end
        end
    end
end