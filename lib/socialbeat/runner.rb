require 'coremidi'

module SocialBeat
  class Event < Struct.new(:type, :timestamp, :data); end;

  class Runner
    PHYSICS_STEP = 2.0 / 100 # 50 FPS

    def initialize
      @canvas = Canvas::OpenGl.new
      @canvas.on_idle    = method(:update)
      @canvas.on_display = method(:draw)

      @physics_accum = 0.0
    end
    
    def run(artist_file)
      @artist_file = artist_file
      @env = {}
      @artist_loader = CodeLoader.new(artist_file,
        :default_class => Artist,
        :on_load  => L{|artist| send_to_reloadable(artist, :setup_environment, @env) },
        :on_error => L{|e| puts "Load error: #{e}" }
      )

      @midi_events = []
      @new_events = []
      @event_mutex = Mutex.new
      Thread.new do
        CoreMIDI::Input.register("Test", "Test", "SocialBeat") do |event|
          midi_event = Event.new(:midi, Time.now, event)
          @event_mutex.synchronize do
            @midi_events << midi_event
          end
        end
      end
      @canvas.init
    end

    def update
      @last_physics_time ||= Time.now
      now = Time.now
      u = now - @last_physics_time 
      
      @artist_loader.update(u)

      @physics_accum += u

      @event_mutex.synchronize do
        @new_events += @midi_events 
        @midi_events = []
      end

      @new_events.each do |event|
        unless event.timestamp.is_a?(Float)
          event.timestamp -= @last_physics_time
        end
      end

      # This loop forces a fixed physics update step, giving us deterministic behaviour 
      while @physics_accum >= PHYSICS_STEP 
        e = @new_events.select {|x| x.timestamp <= PHYSICS_STEP }
        send_to_reloadable(@artist_loader.current_instance, :update, e, @canvas, @env, PHYSICS_STEP)
        @new_events -= e
        @new_events.each do |event|
          event.timestamp -= PHYSICS_STEP
        end
        @physics_accum -= PHYSICS_STEP
      end
      @canvas.refresh
      @last_physics_time = now
      sleep 0.01 # Don't use up all my CPU so I can actually develop this thing
    end

    def draw
      now = Time.now
      u = now - (@last_draw_time || now) 
      @last_draw_time = now

      send_to_reloadable(@artist_loader.current_instance, :draw, @canvas, @env, u)
    end

    def send_to_reloadable(obj, method, *args)
      begin
        obj.send(method, *args)
      rescue NoMethodError, ArgumentError, TypeError, NameError => e
        puts e
      end
    end
  end
end
