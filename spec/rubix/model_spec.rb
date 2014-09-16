require 'spec_helper'

describe Rubix::Model do

  before do
    @model_wrapper = Class.new(Rubix::Model)
    @model_wrapper.zabbix_define :FOO, { :bar => 0, :booz => 1 }
    @model_wrapper.zabbix_attr :snap
    @model_wrapper.zabbix_attr :crackle, :default  => 'how'
    @model_wrapper.zabbix_attr :pop,     :required => true
  end

  it "can define attributes" do
    @model = @model_wrapper.new
    expect(@model.snap).to be_nil
    @model.snap = 3
    expect(@model.snap).to eq(3)
  end

  it "can define attributes with defaults" do
    expect(@model_wrapper.new.crackle).to eq('how')
  end

  it "can define required attributs" do
    expect { @model_wrapper.new.validate }.to raise_error(Rubix::ValidationError)
  end

  it "will define a lookup hash for translating between names and integer codes" do
    expect(@model_wrapper::FOO_CODES[:bar]).to eq(0)
    expect(@model_wrapper::FOO_CODES[:booz]).to eq(1)
    expect(@model_wrapper::FOO_NAMES[0]).to eq(:bar)
    expect(@model_wrapper::FOO_NAMES[1]).to eq(:booz)
  end

  it "will define a lookup hash that acts as a Mash when looking up names to codes" do
    expect(@model_wrapper::FOO_CODES[:bar]).to eq(0)
    expect(@model_wrapper::FOO_CODES['bar']).to eq(0)
  end

end
  
