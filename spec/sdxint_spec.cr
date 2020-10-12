require "spec"
require "../src/datatypes"
require "../src/vm"

describe SDX::Datatypes::SDXInt do
  it "handles eq and ne" do
    SDX::VM.call(SDX::Datatypes::SDXInt.new(5).fields["__eq"], [SDX::Datatypes::SDXInt.new(5)] of SDX::Datatypes::Value).should eq SDX::Datatypes::SDXBool.new(true)
    SDX::VM.call(SDX::Datatypes::SDXInt.new(6).fields["__eq"], [SDX::Datatypes::SDXInt.new(5)] of SDX::Datatypes::Value).should eq SDX::Datatypes::SDXBool.new(false)
    SDX::VM.call(SDX::Datatypes::SDXInt.new(5).fields["__ne"], [SDX::Datatypes::SDXInt.new(5)] of SDX::Datatypes::Value).should eq SDX::Datatypes::SDXBool.new(false)
    SDX::VM.call(SDX::Datatypes::SDXInt.new(6).fields["__ne"], [SDX::Datatypes::SDXInt.new(5)] of SDX::Datatypes::Value).should eq SDX::Datatypes::SDXBool.new(true)
  end

  it "handles arithmetic correctly" do
    SDX::VM.call(SDX::Datatypes::SDXInt.new(5).fields["__add"], [SDX::Datatypes::SDXInt.new(5)] of SDX::Datatypes::Value).should eq SDX::Datatypes::SDXInt.new(10)
    SDX::VM.call(SDX::Datatypes::SDXInt.new(5).fields["__sub"], [SDX::Datatypes::SDXInt.new(5)] of SDX::Datatypes::Value).should eq SDX::Datatypes::SDXInt.new(0)
    SDX::VM.call(SDX::Datatypes::SDXInt.new(5).fields["__mul"], [SDX::Datatypes::SDXInt.new(5)] of SDX::Datatypes::Value).should eq SDX::Datatypes::SDXInt.new(25)
    SDX::VM.call(SDX::Datatypes::SDXInt.new(5).fields["__div"], [SDX::Datatypes::SDXInt.new(5)] of SDX::Datatypes::Value).should eq SDX::Datatypes::SDXInt.new(1)
    SDX::VM.call(SDX::Datatypes::SDXInt.new(5).fields["__pow"], [SDX::Datatypes::SDXInt.new(3)] of SDX::Datatypes::Value).should eq SDX::Datatypes::SDXInt.new(125)
    SDX::VM.call(SDX::Datatypes::SDXInt.new(5).fields["__mod"], [SDX::Datatypes::SDXInt.new(2)] of SDX::Datatypes::Value).should eq SDX::Datatypes::SDXInt.new(1)
  end

  it "can be compared" do
    SDX::VM.call(SDX::Datatypes::SDXInt.new(5).fields["__lt"], [SDX::Datatypes::SDXInt.new(6)] of SDX::Datatypes::Value).should eq SDX::Datatypes::SDXBool.new(true)
    SDX::VM.call(SDX::Datatypes::SDXInt.new(6).fields["__gt"], [SDX::Datatypes::SDXInt.new(6)] of SDX::Datatypes::Value).should eq SDX::Datatypes::SDXBool.new(false)
    SDX::VM.call(SDX::Datatypes::SDXInt.new(5).fields["__le"], [SDX::Datatypes::SDXInt.new(5)] of SDX::Datatypes::Value).should eq SDX::Datatypes::SDXBool.new(true)
    SDX::VM.call(SDX::Datatypes::SDXInt.new(6).fields["__ge"], [SDX::Datatypes::SDXInt.new(5)] of SDX::Datatypes::Value).should eq SDX::Datatypes::SDXBool.new(true)
    SDX::VM.call(SDX::Datatypes::SDXInt.new(5).fields["__le"], [SDX::Datatypes::SDXInt.new(6)] of SDX::Datatypes::Value).should eq SDX::Datatypes::SDXBool.new(true)
    SDX::VM.call(SDX::Datatypes::SDXInt.new(6).fields["__ge"], [SDX::Datatypes::SDXInt.new(6)] of SDX::Datatypes::Value).should eq SDX::Datatypes::SDXBool.new(true)
  end
end
