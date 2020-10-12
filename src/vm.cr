require "./datatypes"
require "big/big_decimal"
require "./bind"

module SDX
  class VM
    property bc : IO
    setter offset : Int32
    @is_main : Bool
    @prefix : String
    getter stack : Array(Datatypes::Value)
    getter scope : Hash(String, Datatypes::Value)

    OP_NAMES = {
      0x04 => "add",
      0x05 => "sub",
      0x06 => "mul",
      0x07 => "div",
      0x08 => "mod",
      0x09 => "pow",
      0x0a => "lt",
      0x0b => "gt",
      0x0c => "le",
      0x0d => "ge",
      0x0e => "eq",
      0x0f => "ne",
    }

    OP_MSGS = {
      0x04 => "add to",
      0x05 => "subtract from",
      0x06 => "multiply",
      0x07 => "divide",
      0x08 => "modulo",
      0x09 => "exponentiate",
      0x0a => "perform less than on",
      0x0b => "perform greater than on",
      0x0c => "perform less than or equal to than on",
      0x0d => "perform greater than or equal to than on",
      0x0e => "compare",
      0x0f => "compare for inequality",
    }

    def self.stringify(val : Datatypes::Value)
      func = val.fields["__as_str"]?
      if func
        return "#{(call(func, [] of Datatypes::Value) || Datatypes::SDXNil.new).internal}"
      else
        return val.internal.to_s
      end
    end

    def self.call(f : Datatypes::Value, args : Array(Datatypes::Value))
      unless f.fields["__call"]? && f.fields["__arity"]?
        Error.vm_error "Cannot call #{Datatypes.base_typename f}"
        return nil
      end
      case f.fields["__arity"]
      when Datatypes::SDXInt
        arity = f.fields["__arity"].as Datatypes::SDXInt
        if args.size != arity.internal
          Error.vm_error "Expected #{arity.internal} arguments, got #{args.size}"
        end
      when Datatypes::SDXInternalArityInt
        arity = f.fields["__arity"].as Datatypes::SDXInternalArityInt
        if args.size != arity.internal
          Error.vm_error "Expected #{arity.internal} arguments, got #{args.size}"
        end
      else
        Error.vm_error "Arity should be an int"
      end
      case f.fields["__call"]
      when Datatypes::SDXNativeFnInternal
        call = f.fields["__call"].as Datatypes::SDXNativeFnInternal
        return call.internal.call(args)
      else
        return call f.fields["__call"], args
      end
    end

    def self.construct(f : Datatypes::Value, args : Array(Datatypes::Value))
      unless f.fields["__new"]? && f.fields["__new_arity"]?
        Error.vm_error "Cannot construct #{Datatypes.base_typename f}"
        return nil
      end
      case f.fields["__new_arity"]
      when Datatypes::SDXInt
        arity = f.fields["__new_arity"].as Datatypes::SDXInt
        if args.size != arity.internal
          Error.vm_error "Expected #{arity.internal} arguments, got #{args.size}"
        end
      when Datatypes::SDXInternalArityInt
        arity = f.fields["__new_arity"].as Datatypes::SDXInternalArityInt
        if args.size != arity.internal
          Error.vm_error "Expected #{arity.internal} arguments, got #{args.size}"
        end
      else
        Error.vm_error "Arity should be an int"
      end
      case f.fields["__new"]
      when Datatypes::SDXNativeFnInternal
        call = f.fields["__new"].as Datatypes::SDXNativeFnInternal
        return call.internal.call(args)
      else
        return call f.fields["__new"], args
      end
    end

    def initialize(bc : IO, is_main = true, prefix = "")
      @bc = bc
      @is_main = is_main
      @offset = 0
      @prefix = prefix
      @stack = [] of Datatypes::Value
      @scope = {
        "dl_call" => Datatypes::SDXNativeFn.new(
          Proc(Array(Datatypes::Value), Datatypes::Value?).new do |args|
            case args[0]
            when Datatypes::SDXStr
              nil
            else
              Error.type_error "Argument one of dl_call must be a string"
            end
            case args[1]
            when Datatypes::SDXStr
              nil
            else
              Error.type_error "Argument two of dl_call must be a string"
            end
            name = args[0].internal.as String
            l = Binding::Lib.new name
            sym = args[1].internal.as String
            arg = args[2]
            u = LibDL::SDXVal.new
            case arg
            when Datatypes::SDXInt
              u.id = LibDL::SDXId::SDXInt
              u.val.sdx_int = arg.internal
            when Datatypes::SDXStr
              u.id = LibDL::SDXId::SDXStr
              u.val.sdx_str = arg.internal
            when Datatypes::SDXBool
              u.id = LibDL::SDXId::SDXBool
              u.val.sdx_bool = arg.internal
            when Datatypes::SDXNum
              u.id = LibDL::SDXId::SDXNum
              u.val.sdx_num = arg.internal.value
            when Datatypes::SDXNil
              u.id = LibDL::SDXId::SDXNil
            else
              Error.type_error "Cannot pass #{Datatypes.base_typename arg} to C yet"
            end
            res = l[sym].call(u)
            case res.id
            when LibDL::SDXId::SDXInt
              return Datatypes::SDXInt.new res.val.sdx_int
            when LibDL::SDXId::SDXStr
              return Datatypes::SDXStr.new String.new(res.val.sdx_str)
            when LibDL::SDXId::SDXBool
              return Datatypes::SDXBool.new res.val.sdx_bool == 1
            when LibDL::SDXId::SDXNum
              return Datatypes::SDXNum.new res.val.sdx_num
            when LibDL::SDXId::SDXNil
              return Datatypes::SDXNil.new
            else
              Error.type_error "Cannot return #{Datatypes.base_typename arg} from C yet"
            end
          end, 3, {} of String => Datatypes::Value),
      } of String => Datatypes::Value
    end

    def seek
      @bc.seek @offset
    end

    def decode_byte
      seek
      @offset += 1
      @bc.read_byte
    end

    def decode_int
      seek
      @offset += 4
      @bc.read_bytes Int32, IO::ByteFormat::LittleEndian
    end

    def decode_num
      seek
      val = decode_str
      BigDecimal.new val.to_f
    end

    def decode_str
      seek
      size = decode_int
      @offset += size
      @bc.read_string size
    end

    def get_from_scope(name : String)
      unless @scope[name]?
        Error.vm_error "No such variable #{name}"
        return nil
      end
      @scope[name]
    end

    def truthy?(val : Datatypes::Value)
      case val
      when Datatypes::SDXNil
        return false
      when Datatypes::SDXBool
        return val.internal
      when Datatypes::SDXStr
        return val.internal.size != 0
      else
        return true
      end
    end

    def clear
      @stack = [] of Datatypes::Value
    end

    def dump
      puts "-- BEGIN STACK DUMP --"
      @stack.each do |val|
        puts VM.stringify val
      end
      puts "-- END STACK DUMP --"
    end

    def run
      if @is_main
        Error.enter_call "top level"
      end

      loop do
        inst = decode_byte.as UInt8
        case inst
        when 0x00 # end
          Error.leave_call
          return :ok
        when 0x01 # make
          make_type = decode_byte
          name = decode_str
          case make_type
          when 1 # var
            @scope[name] = @stack[-1]
            @scope[name].assign_to @prefix + name
          when 2 # fn
            @scope[name] = @stack[-1]
            @scope[name].assign_to @prefix + name
          when 3 # object
            args = [] of String
            decode_int.times do
              args << decode_str
            end
            body = decode_str
            if args.size == 0
              vm = VM.new IO::Memory.new(body), false, name + ":"
              vm.scope.merge! @scope
              Error.enter_call "object #{name}"
              vm.run
              vm.scope.each do |k, v|
                @scope["#{name}:#{k}"] = v
              end
            else
              @scope[name] = Datatypes::SDXObject.new body, args, @scope, name
            end
          end
        when 0x02 # const
          type = decode_byte
          case type
          when 0x01 # int
            val = decode_int
            @stack.push Datatypes::SDXInt.new val, @scope
          when 0x02 # str
            val = decode_str
            @stack.push Datatypes::SDXStr.new val, @scope
          when 0x03 # bool
            val = decode_byte
            @stack.push Datatypes::SDXBool.new val == 1, @scope
          when 0x04 # num
            val = decode_num
            @stack.push Datatypes::SDXNum.new val, @scope
          when 0x05 # nil
            @stack.push Datatypes::SDXNil.new @scope
          when 0x06 # list
            args = [] of Datatypes::Value
            decode_int.times do
              args << @stack.pop
            end
            @stack.push Datatypes::SDXList.new args.reverse, @scope
          when 0x07 # fn
            args = [] of String
            decode_int.times do
              args << decode_str
            end
            body = decode_str
            @stack.push Datatypes::SDXFn.new body, args.reverse, @scope
          when 0x08 # block
            body = decode_str
            @stack.push Datatypes::SDXBlock.new body, @scope
          end
        when 0x03 # get
          name = decode_str
          val = get_from_scope name
          unless val
            return nil
          end
          @stack.push val
        when 0x04..0x0f # add to ne
          rhs, lhs = @stack.pop, @stack.pop
          func = lhs.fields["__#{OP_NAMES[inst]}"]?
          unless func
            Error.vm_error "Cannot #{OP_MSGS[inst]} #{Datatypes.base_typename lhs}"
            return nil
          end
          res = VM.call func, [rhs]
          unless res
            res = Datatypes::SDXNil.new
          end
          @stack.push res
        when 0x10 # call
          argc = decode_int
          args = [] of Datatypes::Value
          callee = @stack.pop
          argc.times do
            args << @stack.pop
          end
          Error.enter_call callee.name
          res = VM.call callee, args
          unless res
            res = Datatypes::SDXNil.new
          end
          @stack.push res
        when 0x11 # jpmi
          val = @stack.pop
          size = decode_int
          if size < 0
            size -= 5
          end
          if truthy? val
            @offset += size
          end
        when 0x12 # jmpn
          val = @stack.pop
          size = decode_int
          if size < 0
            size -= 5
          end
          unless truthy? val
            @offset += size
          end
        when 0x13 # jmp
          size = decode_int
          if size < 0
            size -= 5
          end
          @offset += size
        when 0x14 # index
          index = @stack.pop
          val = @stack.pop
          func = val.fields["__index"]?
          unless func
            Error.vm_error "Cannot index #{Datatypes.base_typename val}"
            return nil
          end
          res = VM.call func, [index]
          unless res
            res = Datatypes::SDXNil.new
          end
          @stack.push res
        when 0x15 # iter
          val = @stack.pop
          func = val.fields["__iter"]?
          unless func
            Error.vm_error "Cannot iterate #{Datatypes.base_typename val}"
            return nil
          end
          res = VM.call func, [] of Datatypes::Value
          unless res
            res = Datatypes::SDXNil.new
          end
          @stack.push res
        when 0x16 # done
          val = @stack.pop
          func = val.fields["__done"]?
          unless func
            Error.vm_error "Cannot iterate #{Datatypes.base_typename val}"
            return nil
          end
          res = VM.call func, [] of Datatypes::Value
          unless res
            res = Datatypes::SDXNil.new
          end
          @stack.push res
        when 0x18 # access
          val = @stack.pop
          name = decode_str
          field = val.fields[name]?
          unless field
            Error.vm_error "#{Datatypes.base_typename val} has no field #{name}"
            return nil
          end
          @stack.push field
        when 0x19 # new
          argc = decode_int
          args = [] of Datatypes::Value
          obj = @stack.pop
          argc.times do
            args << @stack.pop
          end
          Error.enter_call "constructor of #{obj.name}"
          res = VM.construct obj, args
          unless res
            res = Datatypes::SDXNil.new
          end
          @stack.push res
        when 0x20 # clear
          clear
        when 0x21 # dup
          @stack.push @stack[-1]
        when 0x22 # drop
          @stack.pop
        end
      end
    end
  end
end
