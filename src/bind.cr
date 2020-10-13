require "c/dlfcn"
@[Link(ldflags: "-lncursesw -ldl #{__DIR__}/../bin/libsdxdl.so")]
lib LibDL
  enum SDXId
    SDXInt
    SDXStr
    SDXBool
    SDXNum
    SDXNil
  end

  union SDXValI
    sdx_int : LibC::Int
    sdx_str : UInt8*
    sdx_bool : LibC::Int
    sdx_num : LibC::Double
    sdx_nil : LibC::Int
  end

  struct SDXVal
    id : SDXId
    val : SDXValI
  end

  fun sdxdlsym(handle : Void*, symbol : UInt8*) : SDXVal -> SDXVal
end

module SDX
  module Binding
    class Lib
      @handle : Void*

      def initialize(name : String)
        @handle = LibC.dlopen name, 1
      end

      def [](symbol : String)
        LibDL.sdxdlsym(@handle, symbol)
      end
    end
  end
end
