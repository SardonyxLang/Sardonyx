require "spec"
require "../src/datatypes"
require "../src/vm"

describe SDX::Datatypes::SDXList do
  it "handles eq and ne" do
    SDX::VM.call(
      SDX::Datatypes::SDXList.new([
        SDX::Datatypes::SDXInt.new(5),
      ] of SDX::Datatypes::Value).fields["__eq"],
      [
        SDX::Datatypes::SDXList.new([SDX::Datatypes::SDXInt.new(5)] of SDX::Datatypes::Value),
      ] of SDX::Datatypes::Value).should eq SDX::Datatypes::SDXBool.new(true)
    SDX::VM.call(
      SDX::Datatypes::SDXList.new([
        SDX::Datatypes::SDXInt.new(6),
      ] of SDX::Datatypes::Value).fields["__eq"],
      [
        SDX::Datatypes::SDXList.new([SDX::Datatypes::SDXInt.new(5)] of SDX::Datatypes::Value),
      ] of SDX::Datatypes::Value).should eq SDX::Datatypes::SDXBool.new(false)
    SDX::VM.call(
      SDX::Datatypes::SDXList.new([
        SDX::Datatypes::SDXInt.new(5),
      ] of SDX::Datatypes::Value).fields["__ne"],
      [
        SDX::Datatypes::SDXList.new([SDX::Datatypes::SDXInt.new(5)] of SDX::Datatypes::Value),
      ] of SDX::Datatypes::Value).should eq SDX::Datatypes::SDXBool.new(false)
    SDX::VM.call(
      SDX::Datatypes::SDXList.new([
        SDX::Datatypes::SDXInt.new(6),
      ] of SDX::Datatypes::Value).fields["__ne"],
      [
        SDX::Datatypes::SDXList.new([SDX::Datatypes::SDXInt.new(5)] of SDX::Datatypes::Value),
      ] of SDX::Datatypes::Value).should eq SDX::Datatypes::SDXBool.new(true)
  end

  it "can be indexed" do
    SDX::VM.call(
      SDX::Datatypes::SDXList.new([
        SDX::Datatypes::SDXInt.new(5), SDX::Datatypes::SDXInt.new(6),
      ] of SDX::Datatypes::Value).fields["__index"],
      [
        SDX::Datatypes::SDXInt.new(0),
      ] of SDX::Datatypes::Value).should eq SDX::Datatypes::SDXInt.new(5)
    SDX::VM.call(
      SDX::Datatypes::SDXList.new([
        SDX::Datatypes::SDXInt.new(5), SDX::Datatypes::SDXInt.new(6),
      ] of SDX::Datatypes::Value).fields["__index"],
      [
        SDX::Datatypes::SDXInt.new(1),
      ] of SDX::Datatypes::Value).should eq SDX::Datatypes::SDXInt.new(6)
    SDX::VM.call(
      SDX::Datatypes::SDXList.new([
        SDX::Datatypes::SDXInt.new(5), SDX::Datatypes::SDXInt.new(6),
      ] of SDX::Datatypes::Value).fields["__index"],
      [
        SDX::Datatypes::SDXInt.new(-2),
      ] of SDX::Datatypes::Value).should eq SDX::Datatypes::SDXInt.new(5)
    SDX::VM.call(
      SDX::Datatypes::SDXList.new([
        SDX::Datatypes::SDXInt.new(5), SDX::Datatypes::SDXInt.new(6),
      ] of SDX::Datatypes::Value).fields["__index"],
      [
        SDX::Datatypes::SDXInt.new(-1),
      ] of SDX::Datatypes::Value).should eq SDX::Datatypes::SDXInt.new(6)
  end

  it "is iterable" do
    x = SDX::Datatypes::SDXList.new([
      SDX::Datatypes::SDXInt.new(5),
      SDX::Datatypes::SDXInt.new(6),
    ] of SDX::Datatypes::Value)
    SDX::VM.call(x.fields["__iter"], [] of SDX::Datatypes::Value).as(SDX::Datatypes::Value).should eq SDX::Datatypes::SDXInt.new(5)
    SDX::VM.call(x.fields["__iter"], [] of SDX::Datatypes::Value).as(SDX::Datatypes::Value).should eq SDX::Datatypes::SDXInt.new(6)
    SDX::VM.call(x.fields["__done"], [] of SDX::Datatypes::Value).should eq SDX::Datatypes::SDXBool.new(true)
  end
end
