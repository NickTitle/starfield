class Ship
  attr_accessor :angle, :engine_sound, :current_engine_volume, :location, :translation, :velocity, :show_sonar, :sonar_array, :countdown_max, :artifact_to_shut_down, :orbit_speed
  attr_reader   :particle_origin, :sonar_origin
  def initialize(window, ship_number = 1)
    @window = window
    #these are the vertices of the ship (top, left, right, bottom)
    @vert = {'t' => [320,230], 'l' => [310, 265], 'r' =>[330, 265], 'b' =>[320,260]}
    @vert_2 = {'t' => [320,230], 'l' => [310, 265], 'r' =>[330, 265], 'b' =>[320,260]}
    @particle_origin = [320,245]
    @sonar_origin = [320,245]
    @offset = [0,0]
    @offset_counter = [0,0]
    @angle = 0
    @particle_array = []
    @particle_array_2 = []
    @sonar_array = []
    @color = ColorPicker.color('ship_grey')
    sound_obj = Gosu::Sample.new(window, "media/engine2.wav")
    @engine_sound = sound_obj.play(0,1,true)
    @current_engine_volume = 0
    @location = [WORLD_SIZE/2+rand(100), WORLD_SIZE/2+rand(100)]
    @velocity = [0,0]
    @sonar_countdown = 0
    @sonar_countdown_max = 60
    @show_sonar = false
    @artifact_to_shut_down = nil
    @artifact_to_orbit = nil
    @orbit_speed = 0
    @orbit_angle = 0
    @translation = 0
    @particle_array_2 = []
    

    create_particles
    create_sonar
    
  end

  #make the engine particles that fly behind the ship, and make particles for second ship too
  def create_particles
    100.times do
      @particle = Particle.new(@window, self)
      @particle_array.push(@particle)
    end
    100.times do
      @particle = Particle.new(@window, self)
      @particle_array_2.push(@particle)
    end
  end

  def create_sonar
    10.times do
      @sonar = SonarBar.new(@window, self, 0)
      @sonar_array.push(@sonar)
    end
  end

  def update
    # update_offset
    if ![0,4].include?@window.game_state
      @sonar_array.each do |s|
        s.update
      end

      @sonar_countdown -=1
      if @sonar_countdown <= 0
        @sonar_array.each do |s|
          s.reset
        end
        @sonar_countdown = @sonar_countdown_max
      end

      update_ship_position
    else
      @angle = 52
      adjust_world_motion
    end
  end

  def update_world_motion_relative_to_ship(left=false, right=false, up=false)

    if left
      @angle = (@angle-2)%360
    elsif right
      @angle = (@angle+2)%360
    end
    if up
      adjust_world_motion
      adjust_engine_volume("up")
      damp_motion("active")
    else
      adjust_engine_volume("down")
      
      if @artifact_to_shut_down && !(left || right || up)
        adjust_for_orbit
      else
        damp_motion("passive")
      end

    end

    #update particles
    @particle_array.each do |p|
      p.update_position(up)
    end
    @particle_array_2.each do |p|
      p.update_position(up)
    end

  end

  def adjust_world_motion
    wM = @window.world_motion
    radAngle = @angle*Math::PI/180
    @velocity[0] = [ [4, @velocity[0]+0.01*Math.sin(radAngle)].min, -4].max
    @velocity[1] = [ [4, @velocity[1]-0.01*Math.cos(radAngle)].min, -4].max
  end

  def adjust_for_orbit
    aLoc = @artifact_to_shut_down.location
    sLoc = self.location

    @velocity[0] *= 0.9 if @velocity[0].abs > 2
    @velocity[1] *= 0.9 if @velocity[1].abs > 2
    scalar = 0.03 * [distance(aLoc, sLoc)/(HEIGHT/3), 1].min

    @velocity[0] += (sLoc[0] > aLoc[0]) ? -scalar : scalar
    @velocity[1] += (sLoc[1] > aLoc[1]) ? -scalar : scalar
    

    calc_angle = Math.atan2(@velocity[1], @velocity[0]) * 180/ Math::PI
    calc_angle += 360 if calc_angle < 0
    @orbit_angle = calc_angle + 90
    @angle = @orbit_angle
  end

  # pass "up" or "down" to adjust engine volume
  def adjust_engine_volume(direction)
    case direction
      when "up"
        if @current_engine_volume < 1
          @current_engine_volume += 0.025
          @engine_sound.volume = @current_engine_volume
        end
      when "down"
        if @current_engine_volume > 0
          @current_engine_volume *= 0.95
          @current_engine_volume = 0 unless @current_engine_volume > 0.05
          @engine_sound.volume = @current_engine_volume
        end
    end
  end

  def update_ship_position
    @location[0] += @velocity[0]
    @location[1] += @velocity[1]

    # @location[0] = @location[0]%WORLD_SIZE
    # @location[1] = @location[1]%WORLD_SIZE
  end
  
  def damp_motion(motion)
    wM = @window.world_motion

    #active for when buttons are down, passive for when you're just hanging out
    case motion

      when "active"
        #enable cornering based on heading a nearly-cardinal direction
        if (@angle.between?(340,359) || @angle.between?(0,10) || @angle.between?(170, 190))
          @velocity[0] *= 0.985
        elsif @angle.between?(260,280) || @angle.between?(80,100)
          @velocity[1] *= 0.985
        end

      when "passive"
        # reduce speed of the world unless it's already really small
        @velocity[0] *= 0.995 if @velocity[0].abs>0.05
        @velocity[1] *= 0.995 if @velocity[1].abs>0.05

        # spin slowly if the ship isn't being propelled through space
        if @velocity[1] > 0
            @angle = @angle - 0.1%360
        else
            @angle = @angle + 0.1%360
        end

      end
  end

  #unused currently, can move ship relative to the viewport
  def update_offset
    @offset_counter[1] += 0.01
    @offset_counter[1]=@offset_counter[1]%90
    @offset[1] = 30*Math.sin(@offset_counter[1]);
    @offset_counter[0]+=0.005
    @offset_counter[0]=@offset_counter[0]%90
    @offset[0] = 150*Math.sin(@offset_counter[0]);
    # @offset=[0,0]
  end

  def draw
    #render sonar waves
    if @show_sonar
      @sonar_array.each do |s|
        s.draw
      end
    end
    # 
    if @window.is_gameplay_state? || @window.game_state == 0

      #render engine particles
      @particle_array.each do |p|
        p.draw(@offset)
      end
      draw_ship_1

    else
      @window.translate(25,25){
        @particle_array.each do |p|
          p.draw(@offset)
        end
        draw_ship_1  
        
      }
      @window.translate(-25,-25){
        @particle_array_2.each do |p|
          p.draw(@offset)
        end
        draw_ship_2
      }
    end

    # draw_ship_2
  end

  def draw_ship_1
        # draw_ship_2
    oX = @offset[0]
    oY = @offset[1]
    cx = particle_origin[0]
    cy = particle_origin[1]-9
    v = @vert
    ship_grey = @color
    ship_orange = ColorPicker.color('ship_orange')
    b = ColorPicker.color('black')
    dg = ColorPicker.color('dark_grey')
    pb = ColorPicker.color('patch_brown')
    pg = ColorPicker.color('patch_green')
    
    @window.rotate(@angle, particle_origin[0], particle_origin[1]){
      
      #left wing border
      @window.draw_quad(
        cx-6+oX, cy-12+oY, b,
        cx-14+oX, cy-4+oY, b,
        cx-16+oX, cy+14+oY, b,
        cx-5+oX, cy+9+oY, b,
        0
      )
      #right wing border
      @window.draw_quad(
        cx+6+oX, cy-12+oY, b,
        cx+14+oX, cy-4+oY, b,
        cx+16+oX, cy+14+oY, b,
        cx+5+oX, cy+9+oY, b,
        0
      )
      #center border
      @window.draw_quad(
        cx-6+oX, cy-12+oY, b,
        cx+6+oX, cy-12+oY, b,
        cx+5+oX, cy+9+oY, b,
        cx-5+oX, cy+9+oY, b,
        0
      )

      #left wing
      @window.draw_quad(
        cx-6+oX, cy-10+oY, ship_orange,
        cx-12+oX, cy-3+oY, ship_orange,
        cx-14+oX, cy+12+oY, ship_orange,
        cx-5+oX, cy+7+oY, ship_orange,
        0
      )

      #center_square
      @window.draw_quad(
        cx-6+oX, cy-10+oY, ship_orange,
        cx+6+oX, cy-10+oY, ship_orange,
        cx+5+oX, cy+7+oY, ship_orange,
        cx-5+oX, cy+7+oY, ship_orange,
        0
      )

      #right wing
      @window.draw_quad(
        cx+6+oX, cy-10+oY, ship_orange,
        cx+12+oX, cy-3+oY, ship_orange,
        cx+14+oX, cy+12+oY, ship_orange,
        cx+5+oX, cy+7+oY, ship_orange,
        0
      )

      #cockpit edge
      @window.draw_quad(
        cx-7+oX, cy-10+oY, b,
        cx+7+oX, cy-10+oY, b,
        cx+4+oX, cy-5+oY, b,
        cx-4+oX, cy-5+oY, b,
        0
      )

      #cockpit
      @window.draw_quad(
        cx-6+oX, cy-10+oY, dg,
        cx+6+oX, cy-10+oY, dg,
        cx+4+oX, cy-6+oY, dg,
        cx-4+oX, cy-6+oY, dg,
        0
      )

      #left patch edge
      @window.draw_quad(
        cx-13+oX, cy-2+oY, b,
        cx-8+oX, cy-1+oY, b,
        cx-8+oX, cy+4+oY, b,
        cx-15+oX, cy+4+oY, b,
        0
      )

      #left patch
      @window.draw_quad(
        cx-12+oX, cy-1+oY, pb,
        cx-9+oX, cy+oY, pb,
        cx-9+oX, cy+3+oY, pb,
        cx-13+oX, cy+3+oY, pb,
        0
      )

      #right patch edge
      @window.draw_quad(
        cx+14+oX, cy+2+oY, b,
        cx+11+oX, cy+3+oY, b,
        cx+11+oX, cy+8+oY, b,
        cx+15+oX, cy+10+oY, b,
        0
      )

      #right patch
      @window.draw_quad(
        cx+13+oX, cy+3+oY, pg,
        cx+12+oX, cy+4+oY, pg,
        cx+12+oX, cy+7+oY, pg,
        cx+14+oX, cy+9+oY, pg,
        0
      )

    }
  end

  def draw_ship_2
    oX = @offset[0]
    oY = @offset[1]
    v = @vert_2
    ship_grey = @color
    white = ColorPicker.color('white')
    dark_grey = ColorPicker.color('dark_grey')
    
    @window.rotate(@angle, @vert_2['b'][0], @vert_2['b'][1]){
      #left border
      @window.draw_triangle(
        v['t'][0]+oX, v['t'][1]-2+oY, white,
        v['l'][0]-1+oX, v['l'][1]+1+oY, white,
        v['b'][0]+oX, v['b'][1]+oY, white,
        0
      )
      #right border
      @window.draw_triangle(
        v['t'][0]+oX, v['t'][1]-2+oY, white,
        v['r'][0]+1+oX, v['r'][1]+1+oY, white,
        v['b'][0]+oX, v['b'][1]+oY, white,
        0
      )
      #left body
      @window.draw_triangle(
        v['t'][0]+oX, v['t'][1]+oY, ship_grey,
        v['l'][0]+oX, v['l'][1]+oY, ship_grey,
        v['b'][0]+oX, v['b'][1]+oY, ship_grey,
        0
      )
      #right body
      @window.draw_triangle(
        v['t'][0]+oX, v['t'][1]+oY, ship_grey,
        v['r'][0]+oX, v['r'][1]+oY, ship_grey,
        v['b'][0]+oX, v['b'][1]+oY, ship_grey,
        0
      )
      #center cockpit
      @window.draw_quad(
        v['b'][0]-3+oX, v['b'][1]-6+oY, dark_grey,
        v['b'][0]+3+oX, v['b'][1]-6+oY, dark_grey,
        v['b'][0]+5+oX, v['b'][1]-2+oY, dark_grey,
        v['b'][0]-5+oX, v['b'][1]-2+oY, dark_grey,
        0
      )
    }
  end
end