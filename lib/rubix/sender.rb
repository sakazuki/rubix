require 'rubix/binary_json'
require 'rubix/log'
require 'socket'
require 'multi_json'

module Rubix

  # Used to send measurements of pre-defined items to Zabbix.
  #
  # It acts as a pure-Ruby implementation of the +zabbix_sender+
  # utility.
  #
  # @see [Rubix::BinaryJson]
  # @see [Rubix::JavaGateway]
  class Sender

    # The default hostname for the Zabbix trapper service
    DEFAULT_HOST = 'localhost'

    # The default port for the Zabbix trapper
    DEFAULT_PORT = 10051

    # The default Zabbix host to write data for when none is provided
    # at startup or with the data to be written.
    DEFAULT_ZABBIX_HOST     = (ENV['HOSTNAME'] || 'localhost')

    include Logs
    include BinaryJson::Requester

    # Used to encapsulate the wire protcol used by `zabbix_sender`.
    class Request
      
      include BinaryJson::Request

      # The request type.
      REQUEST_TYPE = "sender data"

      # Accepts an array of measurements to send to the Zabbix
      # trapper.
      #
      # @param [Array<Hash>] measurements
      def initialize *measurements
        @data = {data: measurements}
      end
    end

    # Host to write data for when none is provided with the data
    # itself.
    attr_reader :zabbix_host

    # Set the host to write data for when none is provided with the
    # data itself.
    #
    # @param [String, Rubix::Host] new_zabbix_host
    # @return [String] the name of the host
    def zabbix_host= new_zabbix_host
      @zabbix_host = new_zabbix_host.respond_to?(:name) ? new_zabbix_host.name : new_zabbix_host.to_s
    end

    # Create a new sender with the given +settings+.
    #
    # @param [Hash, Configliere::Param] settings
    # @param settings [String] host the hostname of the Zabbix server
    # @param settings [Fixnum] port the port to connect to on the Zabbix server
    # @param settings [String, Rubix::Host] zabbix_host the name of the default Zabbix host
    def initialize settings={}
      super(settings)
      self.zabbix_host = (settings[:zabbix_host] || DEFAULT_ZABBIX_HOST)
    end
    
    # Send measurements to a Zabbix trapper.
    #
    # Each measurement passed should be a Hash with the following keys:
    #
    # * +host+ the host that was measured (will default to the host for this sender)
    # * +key+ the key of the item that was measured
    # * +value+ the value that was measured for the item
    #
    # and optionally:
    #
    # * +time+ the UNIX timestamp at time of measurement
    #
    # The Zabbix server must already have a monitored host with the
    # given item set to be a "Zabbix trapper" type.
    #
    # As per the documentation for the [Zabbix sender
    # protocol](https://www.zabbix.com/wiki/doc/tech/proto/zabbixsenderprotocol),
    # a new TCP connection will be created for each batch of
    # measurements.
    #
    # @param [Array<Hash>] measurements
    def transmit measurements
      request *measurements
    end
    alias_method :<< , :transmit

    # Create a new request for the given measurements.
    #
    # Sets the host of each measurement to the be +zabbix_host+ for
    # this Sender if it isn't already set.
    #
    # @param [Array<Hash>] measurements
    # @return [Request]
    def create_request *measurements
      Request.new(*measurements.flatten.compact.map { |measurement| measurement[:host] ||= zabbix_host ; measurement })
    end

    # Logs the status information returned by the Zabbix trapper at
    # the +DEBUG+ level.
    #
    # @param [Hash] response the parsed response from the Zabbix trapper
    # @param [Array<Hash>] measurements the original measurements
    def handle_response response, *measurements
      debug(response["info"])
    end
    
  end
end
