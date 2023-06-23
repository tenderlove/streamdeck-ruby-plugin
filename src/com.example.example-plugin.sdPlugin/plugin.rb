#!/usr/bin/env ruby

require "logger"
require "async"
require "async/http"
require "async/websocket"
require "json"

log = Logger.new("/tmp/out.txt")

# This class handles different events sent by the stream deck.
# See this URL for all possible events:
#   https://developer.elgato.com/documentation/stream-deck/sdk/events-received/
#
# I've added a few empty methods, but the handle method just logs events
# and continues if it doesn't understand them.
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

  def keyDown payload
  end

  def keyUp payload
    # Each press changes the state.  The state number maps to the index
    # in the states array from manifest.json.
    # When we hit state 3, tell the stream deck to open this URL.
    #
    # Check this URL for other commands you can send the stream deck:
    #
    #   https://developer.elgato.com/documentation/stream-deck/sdk/events-sent/
    #
    if payload["payload"]["state"] == 3
      send payload["context"], "openUrl", { url: "https://ruby-lang.org" }
    end
    @logger.debug payload.inspect
  end

  private

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
