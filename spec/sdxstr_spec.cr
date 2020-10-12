require "spec"
require "../src/datatypes"
require "../src/vm"

describe SDX::Datatypes::SDXStr do
  it "handles eq and ne" do
    SDX::VM.call(SDX::Datatypes::SDXStr.new("a").fields["__eq"], [SDX::Datatypes::SDXStr.new("a")] of SDX::Datatypes::Value).should eq SDX::Datatypes::SDXBool.new(true)
    SDX::VM.call(SDX::Datatypes::SDXStr.new("b").fields["__eq"], [SDX::Datatypes::SDXStr.new("a")] of SDX::Datatypes::Value).should eq SDX::Datatypes::SDXBool.new(false)
    SDX::VM.call(SDX::Datatypes::SDXStr.new("a").fields["__ne"], [SDX::Datatypes::SDXStr.new("a")] of SDX::Datatypes::Value).should eq SDX::Datatypes::SDXBool.new(false)
    SDX::VM.call(SDX::Datatypes::SDXStr.new("b").fields["__ne"], [SDX::Datatypes::SDXStr.new("a")] of SDX::Datatypes::Value).should eq SDX::Datatypes::SDXBool.new(true)
  end
end
