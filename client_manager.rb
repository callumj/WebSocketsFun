class ClientManager
  @@instances = {}
  attr_accessor :clients
  
  def initialize
    self.clients = {}
  end
  
  def register(client, pin)
    self.clients.delete(client)
    self.clients[client] = pin.to_sym
  end
  
  def pin_for(client)
    self.clients[client]
  end
  
  def clients_for(pin)
    results = []
    self.clients.each { |key, val| results << key if (pin.to_sym == val) }
    results
  end
  
  def self.instance(type)
    @@instances = {} if @@instances == nil
    @@instances[type.to_sym] = self.new if @@instances[type.to_sym] == nil
    @@instances[type.to_sym]
  end
  
end