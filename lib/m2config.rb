$: << File.expand_path(File.dirname(__FILE__))

require 'rubygems'
require 'm2config/config'

module M2
  def self.launch_api_server(configdb_path, server_port = 9090)
    klass = M2::Config
    processor = klass::Processor.new(klass::Handler.new(configdb_path))
    transport = Thrift::ServerSocket.new(server_port)
    transport_factory = Thrift::FramedTransportFactory.new
    server = Thrift::NonblockingServer.new(processor, transport, transport_factory)
    server.serve
  end

  def self.remote_call(endpoint_host = 'localhost', endpoint_port = 9090)
    klass = M2::Config
    endpoint = Thrift::Socket.new(endpoint_host, endpoint_port)
    transport = Thrift::FramedTransport.new(endpoint)
    protocol = Thrift::BinaryProtocol.new(transport)
    transport.open
    klass::Client.new(protocol)
  end
end