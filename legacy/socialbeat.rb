$LOAD_PATH.unshift(ENV["RUBY_PROCESSING_PATH"])
require 'ruby-processing'

class Sketch < Processing::App
  WIDTH = 800
  HEIGHT = 600

  def setup
    color_mode RGB, 1.0
    frame_rate 100
    background(0, 0, 0)
    smooth

    @ticks = 0
    @beat_count = 0
    @beat_history = []
    @bang = 0
    @bang_history = []
  end

  def draw
    c = 0.0
    x = 100
    y = 100
    s = 42

    stroke(0)
    fill(0)
    rect(0, 0, WIDTH, HEIGHT)
    stroke(0.5,0,0)
    @beat_history.each do |beat|
      line(beat, 0, beat, HEIGHT) 
    end
    stroke(0.5,0.5,0.5)
    line(@ticks, 0, @ticks, HEIGHT)

    stroke(0.0,0.0,0.5)
    @bang_history << @bang 
    @bang_history.each_with_index do |bang, index|
      x = @ticks - @bang_history.length + index - 1
      line(x, HEIGHT/2 - bang, x, HEIGHT/2 + bang)
    end

    @beat_history.shift if @beat_history.length > beats_per_bar
    @ticks += 1

    @bang_history.shift if @bang_history.length > 200 
    @bang = @bang / 1.3
  end

  def beat!
    @beat_history << @ticks
    @beat_count = (@beat_count + 1) % beats_per_bar
    @ticks = 0 if @beat_count == 0
  end

  def bang!
    @bang += 30
  end

  def beats_per_bar
    4
  end
end

$LOAD_PATH.unshift('vendor/rack-0.4.0/lib')
require 'rack'

P = Sketch.new(:width => 600, :height => 600, :title => "BeatViz")

class Conductor
  def call(env)
    req = Rack::Request.new(env)

    case req.path_info
    when '/beats'
      P.beat!
    when '/bangs'
      P.bang!
    end

    # Default content-type is text/html
    # Default status is 200
    Rack::Response.new.finish do |res|
       res.write(req.path_info) 
    end
  end
end

# Deploy using WEBrick handler
Rack::Handler::WEBrick.run(Conductor.new, :Port => 2000)
