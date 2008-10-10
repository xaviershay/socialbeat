require 'rbcoremidi.bundle'

module CoreMIDI
  module API
    MidiPacket = Struct.new(:timestamp, :data)
  end

  # Unused, but left here for documentation
  def self.number_of_sources
    API.get_num_sources
  end

  class Packet
    attr_accessor :note, :duration, :volume

    def initialize(api_packet)
      self.note     = api_packet.data[0]
      self.duration = api_packet.data[1]
      self.volume   = api_packet.data[2]
    end
  end

  class Input
    def self.register(client_name, port_name, source)
      raise "name must be a String!" unless client_name.class == String

      client = API.create_client(client_name) 
      port = API.create_input_port(client, port_name)
      API.connect_source_to_port(API.get_sources.index(source), port)

      while true
        data = API.check_for_new_data
        if data && !data.empty?
          data.each do |packet|
            yield(Packet.new(packet))
          end
        end
        sleep 0.001
      end
    end
  end
end
