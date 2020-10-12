require "spec"
require "../src/datatypes"
require "../src/vm"
require "big/big_decimal"

describe SDX::Datatypes::SDXNum do
  it "handles eq and ne" do
    SDX::VM.call(SDX::Datatypes::SDXNum.new(5).fields["__eq"], [SDX::Datatypes::SDXNum.new(5)] of SDX::Datatypes::Value).should eq SDX::Datatypes::SDXBool.new(true)
    SDX::VM.call(SDX::Datatypes::SDXNum.new(5).fields["__eq"], [SDX::Datatypes::SDXNum.new(6)] of SDX::Datatypes::Value).should eq SDX::Datatypes::SDXBool.new(false)
    SDX::VM.call(SDX::Datatypes::SDXNum.new(5).fields["__ne"], [SDX::Datatypes::SDXNum.new(5)] of SDX::Datatypes::Value).should eq SDX::Datatypes::SDXBool.new(false)
    SDX::VM.call(SDX::Datatypes::SDXNum.new(5).fields["__ne"], [SDX::Datatypes::SDXNum.new(6)] of SDX::Datatypes::Value).should eq SDX::Datatypes::SDXBool.new(true)
  end

  it "handles arithmetic correctly" do
    SDX::VM.call(SDX::Datatypes::SDXNum.new(5).fields["__add"], [SDX::Datatypes::SDXNum.new(5)] of SDX::Datatypes::Value).should eq SDX::Datatypes::SDXNum.new(10)
    SDX::VM.call(SDX::Datatypes::SDXNum.new(5).fields["__sub"], [SDX::Datatypes::SDXNum.new(5)] of SDX::Datatypes::Value).should eq SDX::Datatypes::SDXNum.new(0)
    SDX::VM.call(SDX::Datatypes::SDXNum.new(5).fields["__mul"], [SDX::Datatypes::SDXNum.new(5)] of SDX::Datatypes::Value).should eq SDX::Datatypes::SDXNum.new(25)
    SDX::VM.call(SDX::Datatypes::SDXNum.new(5).fields["__div"], [SDX::Datatypes::SDXNum.new(5)] of SDX::Datatypes::Value).should eq SDX::Datatypes::SDXNum.new(1)
    SDX::VM.call(SDX::Datatypes::SDXNum.new(5).fields["__pow"], [SDX::Datatypes::SDXNum.new(3)] of SDX::Datatypes::Value).should eq SDX::Datatypes::SDXNum.new(125)
    SDX::VM.call(SDX::Datatypes::SDXNum.new(5).fields["__mod"], [SDX::Datatypes::SDXNum.new(2)] of SDX::Datatypes::Value).should eq SDX::Datatypes::SDXNum.new(1)
  end

  it "can be compared" do
    SDX::VM.call(SDX::Datatypes::SDXNum.new(5).fields["__lt"], [SDX::Datatypes::SDXNum.new(6)] of SDX::Datatypes::Value).should eq SDX::Datatypes::SDXBool.new(true)
    SDX::VM.call(SDX::Datatypes::SDXNum.new(6).fields["__gt"], [SDX::Datatypes::SDXNum.new(6)] of SDX::Datatypes::Value).should eq SDX::Datatypes::SDXBool.new(false)
    SDX::VM.call(SDX::Datatypes::SDXNum.new(5).fields["__le"], [SDX::Datatypes::SDXNum.new(5)] of SDX::Datatypes::Value).should eq SDX::Datatypes::SDXBool.new(true)
    SDX::VM.call(SDX::Datatypes::SDXNum.new(6).fields["__ge"], [SDX::Datatypes::SDXNum.new(5)] of SDX::Datatypes::Value).should eq SDX::Datatypes::SDXBool.new(true)
    SDX::VM.call(SDX::Datatypes::SDXNum.new(5).fields["__le"], [SDX::Datatypes::SDXNum.new(6)] of SDX::Datatypes::Value).should eq SDX::Datatypes::SDXBool.new(true)
    SDX::VM.call(SDX::Datatypes::SDXNum.new(6).fields["__ge"], [SDX::Datatypes::SDXNum.new(6)] of SDX::Datatypes::Value).should eq SDX::Datatypes::SDXBool.new(true)
  end

  it "handles arbitrary precision numbers" do
    SDX::Datatypes::SDXNum.new(BigDecimal.new("5.123456789123456789123456789")).internal.should_not eq BigDecimal.new(5.123456789123456) # truncation
  end
end
