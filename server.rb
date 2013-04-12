$LOAD_PATH.unshift(File.dirname(__FILE__)) unless $LOAD_PATH.include?(File.dirname(__FILE__))

require 'multilogger'
require 'clienthandle'
require 'eventmachine'

SERVER_COUNT = 1

$logger = MultiLogger.new("server.log", true)
$decoder = MessageDecoder.new

EventMachine.run {
	EventMachine.start_server "0.0.0.0", 20000, ClientHandle
	EventMachine.start_server "0.0.0.0", 20002, ServerHandle
}
