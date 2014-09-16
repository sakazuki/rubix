require 'spec_helper'

describe Rubix::Connection do

  let(:server)                 { double("Net::HTTP instance") }
  let(:server_api_version)     { '1.4'                        }

  let(:generic_response)       { double("Net::HTTP::Response instance", :code => 200, :body => '{"result": "foo"}')        }
  
  let(:auth_success_response)  { double("Net::HTTP::Response instance", :code => 200, :body => '{"result": "auth_token"}') }
  let(:auth_failure_response)  { double("Net::HTTP::Response instance", :code => 200, :body => '{"error":{"code":-32602,"message":"Invalid params.","data":"Not authorized"}}') }
  
  let(:supported_version_response)   { double("Net::HTTP::Response instance", :code => 200, :body => '{"result": "1.4"}') }
  let(:unsupported_version_response) { double("Net::HTTP::Response instance", :code => 200, :body => '{"result": "1.3"}') }

  let(:connection) { Rubix::Connection.new('localhost/api.php', 'username', 'password') }
  subject { connection }
  before do
    allow(Net::HTTP).to receive(:new).and_return(server)
  end

  context "before making any requests" do
    it "sends an authorization request" do
      allow(server).to receive(:request).and_return(auth_success_response)
      allow(connection).to receive(:authorize!)
      expect(subject.request_id).to eq(0)
      connection.request('foobar', {})
    end
    context "having received a failed authorization response" do
      before { allow(server).to receive(:request).and_return(auth_failure_response) }
      it "throws an AuthenticationError" do
        expect { connection.request('foobar', {}) }.to raise_error(Rubix::AuthenticationError)
      end
    end
    context "having received a successful authorization response" do
      it "sends a version check request" do
        allow(server).to receive(:request).and_return(auth_success_response, supported_version_response, generic_response)
        expect { connection.request('foobar', {}) }.not_to raise_error
      end
      context "having rejected the server API version" do
        before { allow(server).to receive(:request).and_return(auth_success_response, unsupported_version_response) }
        it "throws a VersionError" do
          expect { connection.request('foobar', {}) }.to raise_error(Rubix::VersionError)
        end
      end
      context "having verified it supports the server API version" do
        it "sends the actual request" do
          allow(server).to receive(:request).and_return(auth_success_response, supported_version_response, generic_response)
          expect { connection.request('foobar', {}) }.not_to raise_error
        end
      end
    end
  end

  context "on subsequent requests" do
    before do
      allow(server).to receive(:request).and_return(auth_success_response, supported_version_response, generic_response)
      connection.request('foobar', {})
    end
    it "should not send any authentication or version check requests" do
      allow(server).to receive(:request).and_return(generic_response)
      expect(connection).not_to receive(:authorize!)
      expect(connection).not_to receive(:check_version!)
      connection.request('foobar', {})
      expect(subject.request_id).to eq(4)
    end
    context "upon receiving a 'Not authorized' response" do
      before { allow(server).to receive(:request).and_return(auth_failure_response) }
      it "authorizes again and repeats the request" do
        allow(server).to receive(:request).and_return(auth_success_response, generic_response)
        connection.request('foobar', {})
        expect(subject.request_id).to eq(4)
      end
    end
  end
end

