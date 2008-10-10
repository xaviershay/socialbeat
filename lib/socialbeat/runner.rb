require 'coremidi'

module SocialBeat
  class Event < Struct.new(:type, :timestamp, :data); end;

  class Runner
    PHYSICS_STEP = 1.0 / 100 # 100 FPS

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
        :on_load  => L{|artist| artist.setup_environment(@env) },
        :on_error => L{ puts "Load error!" }
      )

      @midi_events = []
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
      now = Time.now
      u = now - (@last_physics_time || now) 
      
      @artist_loader.update(u)

      @physics_accum += u

      new_events = []
      @event_mutex.synchronize do
        new_events = @midi_events 
        @midi_events = []
      end

      new_events.each do |event|
        event.timestamp -= (@last_physics_time || now)
      end

      # This loop forces a fixed physics update step, giving us deterministic behaviour 
      while @physics_accum >= PHYSICS_STEP 
        e = new_events.select {|x| x.timestamp < PHYSICS_STEP }
        @artist_loader.current_instance.update(new_events, @canvas, @env, PHYSICS_STEP)
        new_events -= e
        new_events.each do |event|
          event.timestamp -= PHYSICS_STEP
        end
        @physics_accum -= PHYSICS_STEP
      end
      @canvas.refresh
      @last_physics_time = now
    end

    def draw
      now = Time.now
      u = now - (@last_draw_time || now) 
      @last_draw_time = now

      @artist_loader.current_instance.draw(@canvas, @env, u)
    end
  end
end
