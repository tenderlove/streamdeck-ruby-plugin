#!/usr/bin/env ruby

require "logger"
require "async"
require "async/http"
require "async/websocket"
require "json"

log = Logger.new("/tmp/out.txt")

class EventHandler
  def initialize logger, connection
    @logger = logger
    @connection = connection
  end

  def handle event, payload
    if self.respond_to?(event)
      @logger.debug "Got Event: #{event}"
      __send__ event, payload
    else
      @logger.debug "unknown event #{event}"
    end
  end

  def deviceDidConnect payload
    @logger.debug "CONNECTED!"
  end

  def willAppear payload
  end

  def titleParametersDidChange payload
  end

  def keyDown payload
  end

  def keyUp payload
    @logger.debug payload.inspect
  end

  def send context, event, payload
    @connection.write(JSON.dump(context: context, event: event, payload: payload))
  end
end

InitInfo = Struct.new(:port, :pluginUUID, :registerEvent, :info)

init_info = InitInfo.new

ARGV.each_slice(2) do |k, v|
  case k
  when "-port"
    init_info.port = v.to_i
  when "-pluginUUID"
    init_info.pluginUUID = v
  when "-registerEvent"
    init_info.registerEvent = v
  when "-info"
    init_info.info = JSON.parse(v)
  end
end

URL = "http://localhost:#{init_info.port}"

Async do |task|
  endpoint = Async::HTTP::Endpoint.parse(URL)

  Async::WebSocket::Client.connect(endpoint) do |connection|
    # Tell the Stream Deck we've connected
    connection.write(JSON.dump({event: init_info.registerEvent, uuid: init_info.pluginUUID }))

    handler = EventHandler.new log, connection

    while message = connection.read
      msg = JSON.parse message.to_str
      handler.handle(msg["event"], msg)
    end
  end
end
