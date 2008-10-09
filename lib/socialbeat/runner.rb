module SocialBeat
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
      @canvas.init
    end

    def update
      now = Time.now
      u = now - (@last_physics_time || now) 
      @last_physics_time = now
      
      @artist_loader.update(u)

      @physics_accum += u
      # This loop forces a fixed physics update step, giving us deterministic behaviour 
      while @physics_accum >= PHYSICS_STEP 
        @artist_loader.current_instance.update(@canvas, @env, PHYSICS_STEP)
        @physics_accum -= PHYSICS_STEP
      end
      @canvas.refresh
    end

    def draw
      now = Time.now
      u = now - (@last_draw_time || now) 
      @last_draw_time = now

      @artist_loader.current_instance.draw(@canvas, @env, u)
    end
  end
end
