require "bundler"
Bundler.setup
Bundler.require

load "#{File.dirname(__FILE__)}/client_manager.rb"

#Socket based services

class SocketServer < EventMachine::Connection
  @@clients ||= {}
  
  def client_type
    :client
  end
  
  def type
    :device
  end
  
  def post_init
    self.send_data "What up!\r\n"
  end

  def receive_data data
    match_data = data.strip.match(/PIN:(\d+)/)
    existing_pin = ClientManager.instance(self.type).pin_for(self)
    if (match_data != nil && match_data.length > 1)
      pin = match_data[1]
      ClientManager.instance(self.type).register(self,pin)
      send_data "Welcome to #{pin}\r\n"
    elsif (existing_pin != nil)
      ClientManager.instance(self.client_type).clients_for(existing_pin).each do |client|
        #puts "Sending to #{client}"
        client.send data.strip.gsub(/(\r|\n)+/,"")
      end
    end
    close_connection if data =~ /quit/i
  end
  
  def send(val)
    send_data "#{val.strip}\r\n"
  end

  def unbind
    ClientManager.instance(self.type).remove(self)
  end
end

class SocketClientServer < SocketServer
  
  def client_type
    :device
  end
  
  def type
    :client
  end
  
end


#Web resources

#The web man
class WebHelper < Sinatra::Base
    get "/:view.html" do
      if File.exists?("#{File.dirname(__FILE__)}/views/#{params[:view]}.erb")
        erb params[:view].to_sym
      else
        status 404
        ""
      end
    end
    
    get "/loader.js" do
      contents = ""
      File.open("#{File.dirname(__FILE__)}/public/loader.js").each_line{ |s| contents << "#{s}" }
      content_type("text/javascript")
      contents
    end
    
    get '/' do
      if request.user_agent.match(/Mobile\/\w+\s+Safari\/\d+.*\d*/) != nil
        redirect to("/touch.html")
      else
        redirect to("/maps_screen.html")
      end
    end
end
disable :run

# Note that this will block current thread.
EventMachine.run {  
  #socket based devices
  EventMachine.start_server "0.0.0.0", 8091, SocketServer #device service
  EventMachine.start_server "0.0.0.0", 8094, SocketClientServer #client service
  
  #websocket based devices
  
  #Client service
  EventMachine::WebSocket.start(:host => "0.0.0.0", :port => 8090) do |ws|
      ws.onopen {
      }

      ws.onclose { ClientManager.instance(:client).remove(ws) }
      ws.onmessage { |msg|
        match_data = msg.strip.match(/PIN:(\d+)/)
        if (match_data != nil && match_data.length > 1)
          pin = match_data[1]
          ClientManager.instance(:client).register(ws,pin)
        end
      }
  end
  
  #Device service
  EventMachine::WebSocket.start(:host => "0.0.0.0", :port => 8092) do |ws|
      ws.onopen {
      }

      ws.onclose { ClientManager.instance(:device).remove(ws) }
      ws.onmessage { |data|
        match_data = data.strip.match(/PIN:(\d+)/)
        existing_pin = ClientManager.instance(:device).pin_for(ws)
        if (match_data != nil && match_data.length > 1)
          pin = match_data[1]
          ClientManager.instance(:device).register(ws,pin)
        elsif (existing_pin != nil)
          ClientManager.instance(:client).clients_for(existing_pin).each do |client|
            #puts "Sending #{data} to #{client}"
            client.send data.strip.gsub(/(\r|\n)+/,"")
          end
        end
        close_connection if data =~ /quit/i
      }
  end
  
  Thin::Server.start WebHelper, '0.0.0.0', 8093
}