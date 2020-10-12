require "spec"
require "../src/datatypes"
require "../src/vm"

describe SDX::Datatypes::SDXNil do
  it "handles eq and ne" do
    SDX::VM.call(SDX::Datatypes::SDXNil.new.fields["__eq"], [SDX::Datatypes::SDXNil.new] of SDX::Datatypes::Value).should eq SDX::Datatypes::SDXBool.new(true)
  end
end
