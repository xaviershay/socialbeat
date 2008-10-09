module SocialBeat
  class Runner
    def initialize
      @canvas = Canvas::OpenGl.new
      @canvas.on_idle    = method(:update)
      @canvas.on_display = method(:draw)
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
      u = now - (@last_time || now) 
      @last_time = now
      
      @artist_loader.update(u)

      @artist_loader.current_instance.update(@canvas, @env, 0.01)
      @canvas.refresh
    end

    def draw
      @artist_loader.current_instance.draw(@canvas, @env, 0.01)
    end
  end
end
