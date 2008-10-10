class self::Simple < SocialBeat::Artist
  # Ensure that everything you want in the environment is there
  # Data may already exist from a previous artist
  def setup_environment(env)
    env[:current_color] ||= [0.0, 0.0, 0.0]
  end

  # Slowly morph the current color towards the target color
  def update(events, canvas, env, u)
    events.each do |event|
      env[:current_color] = kick_color if event.data.note == 146
    end
    colors = env[:current_color]
    colors.each_with_index do |a, i|
      colors[i] += (base_color[i] - a) * u * 5
    end
  end

  # Draw a simple filled circle with the current color
  def draw(canvas, env, u)
    canvas.fill(*env[:current_color])
    canvas.circle(0, 0, 50)
  end

  protected

  def base_color
    [0.5, 0.0, 0.0]
  end

  def kick_color  
    [0.7, 0.0, 0.7]
  end
end
