require 'spec_helper'

describe Rubix::Sender do

  subject { Rubix::Sender.new(:zabbix_host => "localhost") }
  
  let(:measurement) { { key: 'question.life.universe.everything', value: 42 } }

  it "has sensible defaults" do
    expect(subject.host).to eq(Rubix::Sender::DEFAULT_HOST)
    #expect(subject.server).to eq('localhost')
    #expect(subject.port).to eq(10051)
  end

  it "adds its default host to measurements" do
    expect(subject.format_measurement(measurement)[:host]).to eq(subject.host)
  end

  it "opens and closes a socket on each write" do
    socket = double("TCPSocket instance")
    allow(TCPSocket).to receive(:new).with(subject.host, subject.port).and_return(socket)
    allow(socket).to receive(:write)
    allow(socket).to receive(:recv)
    allow(socket).to receive(:close)
    subject.transmit(measurement)
  end

end
  
