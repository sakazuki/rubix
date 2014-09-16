require 'spec_helper'
require 'multi_json'

describe Rubix::Response do

  def response code, params={}
    Rubix::Response.new(double("Net::HTTPResponse instance", code: code.to_s, body: MultiJson.dump({"jsonrpc" => "2.0"}.merge(params))))
  end

  describe "500" do
    subject { response(500) }
    it "a 5xx response" do
      expect(subject.non_200?).to be true
      expect(subject.error?).to be true
    end
  end

  describe "400" do
    subject { response(400) }
    it "a 4xx response" do
      expect(subject.non_200?).to be true
      expect(subject.error?).to be true
    end
  end

  describe "200" do
    subject { response(200) }
    it "a 200 response" do
p subject
      expect(subject.non_200?).to be false
    end
    describe "with a result that is" do
      subject { response(200, 'result' => '') }
      it "an empty String" do
p subject
        expect(subject.has_data?).to be false
        expect(subject.string?).to be false
        expect(subject.array?).to be false
        expect(subject.hash?).to be false
      end
    end
    describe "with a result that is" do
      subject { response(200, 'result' => []) }
      it "an empty Array" do
p subject
        expect(subject.has_data?).to be false
        expect(subject.string?).to be false
        expect(subject.array?).to be false
        expect(subject.hash?).to be false
      end
    end
    describe "with a result that is" do
      subject { response(200, 'result' => {}) }
      it "an empty Hash" do
p subject
        expect(subject.has_data?).to be false
        expect(subject.string?).to be false
        expect(subject.array?).to be false
        expect(subject.hash?).to be false
      end
    end
    describe "with a result that is" do
      subject { response(200, 'result' => 'hello there') }
      it "a String" do
p subject
        expect(subject.has_data?).to be true
        expect(subject.string?).to be true
        expect(subject.array?).to be false
        expect(subject.hash?).to be false
        expect(subject.result).to eq('hello there')
      end
    end
    describe "with a result that is" do
      subject { response(200, 'result' => ['hello', 'there']) }
      it "an Array" do
p subject
        expect(subject.has_data?).to be true
        expect(subject.string?).to be false
        expect(subject.array?).to be true
        expect(subject.hash?).to be false
        expect(subject.result).to eq([ 'hello', 'there' ])
      end
    end
    describe "with a result that is" do
      subject { response(200, 'result' => {'hello' => 'there'}) }
      it "a Hash" do
p subject
        expect(subject.has_data?).to be true
        expect(subject.string?).to be false
        expect(subject.array?).to be false
        expect(subject.hash?).to be true
        expect(subject.result).to eq({ 'hello' => 'there' })
      end
    end
    describe "with a result that is" do
      subject { response(200, 'error' => { 'message' => 'foobar'}) }
      it "with an error message" do
p subject
        expect(subject.has_data?).to be false
        expect(subject.string?).to be false
        expect(subject.array?).to be false
        expect(subject.hash?).to be false
        expect(subject.error?).to be true
        expect(subject.error_message).to eq('foobar')
      end
    end
  end
end
