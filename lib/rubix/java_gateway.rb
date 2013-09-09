require 'rubix/binary_json'
require 'rubix/log'
require 'socket'
require 'multi_json'

module Rubix

  # Used to obtain JMX measurements from local or remote Java
  # processes via [the Zabbix Java
  # Gateway](https://www.zabbix.com/documentation/2.0/manual/concepts/java).
  #
  # The protocol spoken by the gateway is similar to that spoken by
  # the +zabbix_sender+ utility.
  #
  # @see [Rubix::BinaryJson]
  # @see [Rubix::Sender]
  class JavaGateway

    # The default host for the Zabbix Java gateway
    DEFAULT_HOST = 'localhost'

    # The default port for the Zabbix Java gateway
    DEFAULT_PORT = 10052

    include Logs
    include BinaryJson::Requester

    # Used to encapsulate the wire protocol used by Zabbix Java
    # gateway.
    #
    # @see [BinaryJson::Request]
    class JMXRequest

      include  BinaryJson::Request

      # The request type for a JMX measurement.
      REQUEST_TYPE = 'java gateway jmx'

      # Create a new JMXRequest.
      #
      # @param [Hash] jvm
      # @option jvm [String] host the host running the JVM to measure
      # @option jvm [Integer] port the JMX port the JVM has opened
      # @option jvm [String] username the JMX username for the JVM
      # @option jvm [String] password the JMX password for the JVM
      # @option [Aarray<Hash>] measurements a list of JMX properties to measure
      def initialize jvm, *measurements
        @jvm          = jvm
        @measurements = measurements.flatten.compact
      end

      # The data that will be send with the request.
      #
      # @return [Hash]
      def data
        {
          conn:     @jvm[:host],
          port:     @jvm[:port],
          username: @jvm[:username],
          password: @jvm[:password],
          keys:     @measurements.map { |measurement| "jmx[#{measurement[:bean]},#{measurement[:attribute]}]" },
        }
      end
    end

    # Make JVM `measurements` for a JVM described by `jvm`.
    #
    # Each JVM property to measure must be a Hash with the following
    # keys:
    #
    # * the JMX +bean+ name
    # * the JMX attribute name
    #
    # @example Measure some data from Kafka
    #
    #   gateway = JavaGateway.new
    #   gateway.measure({host: 'kafka.example.com', port: 9999}, {bean: 'kafka:type=kafka.logs.queue_name-0', attribute: 'Size'}, ...)
    #
    # @param [Hash] jvm
    # @option jvm [String] host the host running the JVM to measure
    # @option jvm [Integer] port the JMX port the JVM has opened
    # @option jvm [String] username the JMX username for the JVM
    # @option jvm [String] password the JMX password for the JVM
    # @option [Aarray<Hash>] measurements a list of JMX properties to measure
    def measure jvm, *measurements
      request(jvm, *measurements)
    end

    # Create a JMX request that can be sent to a Java gateway.
    #
    # @param [Hash] jvm
    # @option jvm [String] host the host running the JVM to measure
    # @option jvm [Integer] port the JMX port the JVM has opened
    # @option jvm [String] username the JMX username for the JVM
    # @option jvm [String] password the JMX password for the JVM
    # @option [Aarray<Hash>] measurements a list of JMX properties to measure
    def create_request jvm, *measurements
      JMXRequest.new(jvm, *measurements)
    end

    # Munge the parsed response with the original measurements.
    #
    # @param [Hash] response the parsed response
    # @param [Hash] jvm the original options that defined the JVM
    # @param [Array<Hash>] measurements
    def handle_response response, jvm, *measurements
      if response['response'] == 'success'
        [].tap do |result|
          (response['data'] || []).each_with_index do |value, index|
            res = {}
            res[:value] = parse(value['value']) if value['value']
            res[:error] = value['error'] if value['error']
            res.merge!(measurements[index] || {})
            res[:host] = jvm[:host]
            res[:port] = jvm[:port]
            result << res
          end
        end
      else
        error(response)
      end
    end

    def parse val
      return val unless val.is_a?(String)
      case
      when val =~ /^\d+$/     then val.to_i
      when val =~ /^[\.\d]+$/ then val.to_f
      else
        val
      end
    end
    
  end
end
