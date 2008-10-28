reloadable self::ParticleBox do
  depend('particle')

  def gaussian_rand
    u1 = 0
    u2 = 0
    w = 0
    begin
        u1 = 2 * rand() - 1
        u2 = 2 * rand() - 1
        w = u1*u1 + u2*u2
    end while (w >= 1)
    w = Math.sqrt((-2*Math.log(w))/w)
    [ u2*w, u1*w ]
  end

  def setup_environment(env)
    {
      :particles       => [100, 5, 25],
      :click_particles => [60, 5, 15]
    }.each_pair do |key, (n, stddev, median)|
      env[key] = (0..n).collect do |i|
        p = Particle.new
        r = gaussian_rand[0] * stddev + median
        a = rand * 2 * Math::PI
        p.position      = [Math.cos(a) * r, Math.sin(a) * r, 0 * rand]
        p.last_position = p.position.dup
        p.mass = rand + 0.5
        p
      end
    end

    env[:x] ||= 0
    env[:plane]       = [[0, 0, 0], [0, 0, 1.0]]
    env[:click_plane] = [[0, 0, 0], [0, 0, 1.0]]

    env[:colors] ||= {}
    env[:colors][:a] ||= [0, 0, 0]
    env[:colors][:b] ||= [0, 0, 0]

    env[:target_colors] = {
      :a => [[0.0, 0.0, 0.7], [0.5, 0.0, 0.5]],
      :b => [[0.0, 0.6, 0.0], [0.0, 0.6, 1.0]]
    }
  end

  def op(operator, v1, v2)
    (0..2).collect {|i| v1[i].send(operator, v2[i]) }
  end

  self::Z = 2
  self::POINT = 0

  def update(events, canvas, env, u)
    events.each do |event|
      if event.data.is_a?(CoreMIDI::Events::NoteOn)
        if event.data.pitch == 119
          env[:target_colors].each_pair do |key, colors|
            colors << colors.shift
          end
        end

        env[:plane][POINT][Z] = 0.07 if event.data.pitch == 36
        env[:click_plane][POINT][Z] = 0.07 if event.data.pitch == 37
      end
    end

    {
      :particles       => env[:plane],
      :click_particles => env[:click_plane]
    }.each_pair do |key, plane|
      if plane[POINT][Z] > 0
        plane[POINT][Z] -= 0.01 #u * 0.5
      else
        plane[POINT][Z] = 0
      end

      env[key].each do |particle|
        # Move
        delta = op(:-, particle.position, particle.last_position)
        particle.last_position = particle.position.dup
        particle.position = op(:+, particle.position, delta)

        # Apply forces
        particle.position[Z] -= 0.5 * u * particle.mass

        # Contraints
        z = particle.position[Z]
        l_z = particle.last_position[Z]
        p_z = plane[POINT][Z]
        if z < p_z
          if l_z > p_z
            particle.last_position[Z] = p_z - (l_z - z) * 0.0
          end
          particle.position[Z] = p_z
        end
      end
    end

    env[:colors].each_pair do |key, color|
      color.each_with_index do |a, i|
        color[i] += (env[:target_colors][key].first[i] - a) * u
      end
    end

    env[:x] += u * 8
  end

  def draw(canvas, env, u)
    canvas.use_3d!
    canvas.look_at([80, 80, 65], [0, 0, 0], [0, 0, 1])
    canvas.rotate(env[:x], [0, 0, 1]) 

    canvas.fill(0.0, 0.0, 1.0)
    {
      :particles       => env[:colors][:a],
      :click_particles => env[:colors][:b]
    }.each_pair do |key, color|
      canvas.fill(*color)
      env[key].each do |particle|
        canvas.point(*particle.position)
      end
    end
  end
end
