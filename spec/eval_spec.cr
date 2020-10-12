require "spec"
require "../src/parser"
require "../src/compiler"
require "../src/vm"
require "../src/datatypes"
require "big/big_decimal"

def eval(code : String)
  ast = SDX::Parser::Parser.parse(code)
  if ast
    bc = SDX::Compiler.compile ast, false
    vm = SDX::VM.new IO::Memory.new bc
    vm.run
    return vm.stack[-1]?
  end
end

describe SDX::VM do
  it "handles literals" do
    eval("5").should eq SDX::Datatypes::SDXInt.new(5)
    eval("-5").should eq SDX::Datatypes::SDXInt.new(-5)
    eval("-5.0").should eq SDX::Datatypes::SDXNum.new(BigDecimal.new("-5.0"))
    eval("5.0").should eq SDX::Datatypes::SDXNum.new(BigDecimal.new("5.0"))
    eval("\"\"").should eq SDX::Datatypes::SDXStr.new("")
    eval("\"abc\"").should eq SDX::Datatypes::SDXStr.new("abc")
    eval("[]").should eq SDX::Datatypes::SDXList.new([] of SDX::Datatypes::Value)
    eval("[1]").should eq SDX::Datatypes::SDXList.new([
      SDX::Datatypes::SDXInt.new(1),
    ] of SDX::Datatypes::Value)
    eval("[1, 2, 3]").should eq SDX::Datatypes::SDXList.new([
      SDX::Datatypes::SDXInt.new(1),
      SDX::Datatypes::SDXInt.new(2),
      SDX::Datatypes::SDXInt.new(3),
    ] of SDX::Datatypes::Value)
    eval("[1, 2, 3, \"abc\"]").should eq SDX::Datatypes::SDXList.new([
      SDX::Datatypes::SDXInt.new(1),
      SDX::Datatypes::SDXInt.new(2),
      SDX::Datatypes::SDXInt.new(3),
      SDX::Datatypes::SDXStr.new("abc"),
    ] of SDX::Datatypes::Value)
    eval("true").should eq SDX::Datatypes::SDXBool.new(true)
    eval("false").should eq SDX::Datatypes::SDXBool.new(false)
    eval("nil").should eq SDX::Datatypes::SDXNil.new
  end

  it "handles arithmetic" do
    eval("5 + 5").should eq SDX::Datatypes::SDXInt.new(10)
    eval("5 - 5").should eq SDX::Datatypes::SDXInt.new(0)
    eval("5 * 5").should eq SDX::Datatypes::SDXInt.new(25)
    eval("5 / 5").should eq SDX::Datatypes::SDXInt.new(1)
    eval("5 ^ 3").should eq SDX::Datatypes::SDXInt.new(125)
    eval("5 % 2").should eq SDX::Datatypes::SDXInt.new(1)
    eval("5.0 + 5.0").should eq SDX::Datatypes::SDXInt.new(BigDecimal.new "10")
    eval("5.0 - 5.0").should eq SDX::Datatypes::SDXInt.new(BigDecimal.new "0")
    eval("5.0 * 5.0").should eq SDX::Datatypes::SDXInt.new(BigDecimal.new "25")
    eval("5.0 / 5.0").should eq SDX::Datatypes::SDXInt.new(BigDecimal.new "1")
    eval("5.0 ^ 3.0").should eq SDX::Datatypes::SDXInt.new(BigDecimal.new "125")
    eval("5.0 % 2.0").should eq SDX::Datatypes::SDXInt.new(BigDecimal.new "1")
  end

  it "handles variables" do
    eval("a = 5").should eq SDX::Datatypes::SDXInt.new(5)
    eval("a = 5 a").should eq SDX::Datatypes::SDXInt.new(5)
    eval("a = 5 b = a").should eq SDX::Datatypes::SDXInt.new(5)
    eval("a = 5 b = a b").should eq SDX::Datatypes::SDXInt.new(5)
  end

  it "handles control flow" do
    eval("if true 5 else 6").should eq SDX::Datatypes::SDXInt.new(5)
    eval("if false 5 else 6").should eq SDX::Datatypes::SDXInt.new(6)
    eval("i = 0 while i < 5 i = i + 1 i").should eq SDX::Datatypes::SDXInt.new(5)
    eval("for [1, 2, 3] _").should eq SDX::Datatypes::SDXInt.new(3)
  end

  it "can call functions and blocks" do
    eval("{ _ }(5)").should eq SDX::Datatypes::SDXInt.new(5)
    eval("fn f(x) x f(5)").should eq SDX::Datatypes::SDXInt.new(5)
  end

  it "can index lists" do
    eval("[1, 2, 3][1]").should eq SDX::Datatypes::SDXInt.new(2)
  end

  it "can use namespace objects" do
    eval("object X y = 5 X:y").should eq SDX::Datatypes::SDXInt.new(5)
    eval("object X object Y z = 5 X:Y:z").should eq SDX::Datatypes::SDXInt.new(5)
  end

  it "can instantiate objects" do
    eval("object X(y) z = y obj = new X(5) obj.z").should eq SDX::Datatypes::SDXInt.new(5)
  end
end
