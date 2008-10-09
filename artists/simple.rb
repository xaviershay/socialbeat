class Simple < SocialBeat::Artist
  # Ensure that everything you want in the environment is there
  # Data may already exist from a previous artist
  def setup_environment(env)
    env[:current_color] ||= [0.0, 0.0, 0.0]
  end

  # Slowly morph the current color towards the target color
  def update(canvas, env, u)
    colors = env[:current_color]
    colors.each_with_index do |a, i|
      colors[i] += (target_color[i] - a) * u
    end
  end

  # Draw a simple filled circle with the current color
  def draw(canvas, env, u)
    canvas.fill(*env[:current_color])
    canvas.circle(100, 100, 20)
  end

  protected

  def target_color
    [1.0, 0.0, 0.0]
  end
end
