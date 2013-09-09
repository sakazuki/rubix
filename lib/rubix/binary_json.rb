require 'multi_json'

module Rubix

  # A module that contains functionality for working with the (odd)
  # semi-binary, semi-JSON wire protocol used by Zabbix tools
  # internally.
  #
  # Instead of sending a simple JSON string, the protocol used by
  # Zabbix looks like this
  #
  #   HEADER + JSON_BODY_SIZE + FOOTER + JSON_BODY
  #
  # This module contains a +Request+ module for encapsulating building
  # a byte-sequence like this from a JSON-serializable data structure
  # as well as a +Requester+ module for ease in mediating sending
  # requests and parsing responses.
  #
  # The following links provide details on the protocol used by Zabbix
  # to receive data:
  #
  # * https://www.zabbix.com/forum/showthread.php?t=20047&highlight=sender
  # * https://gist.github.com/1170577
  # * http://spin.atomicobject.com/2012/10/30/collecting-metrics-from-ruby-processes-using-zabbix-trappers/?utm_source=rubyflow&utm_medium=ao&utm_campaign=collecting-metrics-zabix
  module BinaryJson

    # The header that must appear first in all requests.
    HEADER = "ZBXD\1".encode("ascii")

    # The size in bytes of the header.
    HEADER_SIZE = 5

    # The size in bytes of "size of the JSON body".
    JSON_BODY_SIZE_SIZE = 8

    # THe footer that must appear just before the JSON body.
    FOOTER = "\x00\x00\x00\x00"

    # A module that wraps serializing some data as a particular
    # request type.
    #
    # @see [Sender::Request]
    # @see [JavaGateway::JMXRequest]
    module Request

      # The type of the request.
      #
      # @return [String]
      def request_type
        self.class::REQUEST_TYPE
      end
      
      # The raw string representation of this request.
      #
      # @return [String]
      def to_s
        preamble + json_body
      end

      # The data that will be included with the request.
      # 
      # @return [Hash]
      def data
        @data || {}
      end
      
      # The full preamble of the request, including header, body size
      # information, and footer.
      #
      # @return [String]
      def preamble
        HEADER + [json_body.bytesize].pack("i") + FOOTER
      end

      # The JSON body of the request.
      #
      # This method memoizes its result because changes in the body
      # will affect the preamble.
      #
      # @return [String]
      def json_body
        @body ||= MultiJson.dump({request: request_type}.merge(data))
      end
      
    end

    # A module that wraps the functionality around connecting to a
    # Zabbix service which speaks the binary JSON protocol, sending it
    # requests, and parsing and handling the responses.
    #
    # @see [Sender]
    # @see [JavaGateway]
    module Requester

      # The host to send requests to.
      attr_accessor :host

      # The port on the host to send requests to.
      attr_accessor :port

      # The TCP socket used for sending and receiving data.
      attr_accessor :socket

      # Create a new Requester
      #
      # @param [Hash] settings
      # @option settings [String] host the host to send requests to
      # @option settings [Integer] port the port on the host to send requests to
      def initialize settings={}
        self.host = (settings[:host] || self.class::DEFAULT_HOST)
        self.port = (settings[:port] || self.class::DEFAULT_PORT)
      end

      # Send a request, wait for and parse the response, and handle
      # it.
      #
      # @see #create_request
      def request *args
        self.socket = TCPSocket.new(host, port)
        send_request(create_request(*args))
        parsed_response = read_response()
        self.socket.close
        handle_response(parsed_response, *args)
      end

      # Return a request that can properly serialize into the binary
      # JSON protocol.
      #
      # @return [#to_s]
      def create_request *args
        Request.new
      end

      # Send a request.
      #
      # @param [#to_s] request
      def send_request request
        socket.write(request)
      end

      # Read and parse the response from the host.
      #
      # @return [Hash] the parsed response or error information
      def read_response
        header = socket.recv(BinaryJson::HEADER_SIZE)
        return { error: "Invalid header", header: header } unless header == BinaryJson::HEADER
        data_header = socket.recv(BinaryJson::JSON_BODY_SIZE_SIZE)
        length      = data_header[0,BinaryJson::JSON_BODY_SIZE_SIZE / 2].unpack("i")[0]
        MultiJson.load(socket.recv(length))
      end
      
    end
  end
end

