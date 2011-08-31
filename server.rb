require 'eventmachine'
require 'em-websocket'
require 'sinatra'
require 'thin'

load "#{File.dirname(__FILE__)}/client_manager.rb"

module EchoServer
  @@clients ||= {}
  
  def post_init
    self.send_data "What up!\r\n"
  end

  def receive_data data
    match_data = data.strip.match(/PIN:(\d+)/)
    existing_pin = ClientManager.instance(:device).pin_for(self)
    if (match_data != nil && match_data.length > 1)
      pin = match_data[1]
      ClientManager.instance(:device).register(self,pin)
      send_data "Welcome to #{pin}\r\n"
    elsif (existing_pin != nil)
      ClientManager.instance(:client).clients_for(existing_pin).each do |client|
        puts "Sending to #{client}"
        client.send data.strip.gsub(/(\r|\n)+/,"")
      end
    end
    close_connection if data =~ /quit/i
  end

  def unbind
  end
end

# Note that this will block current thread.
EventMachine.run {
  
  #client-display system
  EventMachine::WebSocket.start(:host => "0.0.0.0", :port => 8080) do |ws|
      ws.onopen {
      }

      ws.onclose { puts "Connection closed" }
      ws.onmessage { |msg|
        match_data = msg.strip.match(/PIN:(\d+)/)
        if (match_data != nil && match_data.length > 1)
          pin = match_data[1]
          puts pin
          ClientManager.instance(:client).register(ws,pin)
        end
      }
  end
  
  #socket based devices
  EventMachine.start_server "0.0.0.0", 8081, EchoServer
  
  #websocket based devices
  EventMachine::WebSocket.start(:host => "0.0.0.0", :port => 8082) do |ws|
      ws.onopen {
      }

      ws.onclose { puts "Connection closed" }
      ws.onmessage { |data|
        puts data
        match_data = data.strip.match(/PIN:(\d+)/)
        existing_pin = ClientManager.instance(:device).pin_for(ws)
        if (match_data != nil && match_data.length > 1)
          pin = match_data[1]
          ClientManager.instance(:device).register(ws,pin)
        elsif (existing_pin != nil)
          ClientManager.instance(:client).clients_for(existing_pin).each do |client|
            puts "Sending #{data} to #{client}"
            client.send data.strip.gsub(/(\r|\n)+/,"")
          end
        end
        close_connection if data =~ /quit/i
      }
  end
  
  #The web man
  class WebHelper < Sinatra::Base
      get "/:view" do
        erb params[:view].to_sym
      end
      
      get '/' do
        puts request.user_agent
        if request.user_agent.match(/Mobile\/\w+\s+Safari\/\d+.*\d*/) != nil
          redirect to("/touch")
        else
          redirect to("/maps_screen")
        end
      end
  end
  disable :run
  Thin::Server.start WebHelper, '0.0.0.0', 8083
}