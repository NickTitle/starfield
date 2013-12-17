class Ship
  attr_accessor :angle, :vert, :engine_sound, :current_engine_volume, :world_position, :show_sonar, :sonar_array, :countdown_max, :artifact_to_shut_down
  
  def initialize(window)
    @window = window
    #these are the vertices of the ship (top, left, right, bottom)
    @vert = {'t' => [320,230], 'l' => [310, 265], 'r' =>[330, 265], 'b' =>[320,260]}
    @offset = [0,0]
    @offset_counter = [0,0]
    @angle = 0
    @particle_array = []
    @sonar_array = []
    @color = ColorPicker.color('ship_grey')
    sound_obj = Gosu::Sample.new(window, "media/engine2.wav")
    @engine_sound = sound_obj.play(0,1,true)
    @current_engine_volume = 0
    @world_position = [WORLD_SIZE/2, WORLD_SIZE/2]
    create_particles
    create_sonar
    @countdown = 0
    @countdown_max = 60
    @show_sonar = false
    @artifact_to_shut_down = nil
  end

  #make the engine particles that fly behind the ship
  def create_particles
    100.times do
      @particle = Particle.new(@window, self)
      @particle_array.push(@particle)
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
    @particle_array.each do |p|
      p.update_position
    end

    @sonar_array.each do |s|
      s.update
    end

    @countdown -=1
    if @countdown <= 0

      @sonar_array.each do |s|
        s.reset
      end

      @countdown = @countdown_max

    end

    update_world_motion_relative_to_ship
    update_ship_position
  end

  def update_world_motion_relative_to_ship
    
    if @window.pause_for_story
      damp_motion("passive")

      if @window.story_state == 11 && (@window.button_down? Gosu::KbSpace)
        return if Time.now - @window.last_story_update_time < 1
        if @artifact_to_shut_down != nil
          @artifact_to_shut_down.found = true
        end
      end
      return
    end

    if ([7,14].include?@window.story_state) && ((@window.button_down? Gosu::KbLeft) || (@window.button_down? Gosu::KbRight) || (@window.button_down? Gosu::KbUp))
      @window.writer.set_text=""
    end
    
    wM = @window.world_motion

    if @window.button_down? Gosu::KbLeft or @window.button_down? Gosu::GpLeft then
      @angle = (@angle-2)%360
    end
    if @window.button_down? Gosu::KbRight or @window.button_down? Gosu::GpRight then
      @angle = (@angle+2)%360
    end
    if @window.button_down? Gosu::KbUp or @window.button_down? Gosu::GpUp then
      radAngle = @angle*Math::PI/180
      wM[0] = [ [4, wM[0]-0.01*Math.sin(radAngle)].min, -4].max
      wM[1] = [ [4, wM[1]+0.01*Math.cos(radAngle)].min, -4].max
      adjust_engine_volume("up")
      damp_motion("active")
    else
      adjust_engine_volume("down")
      damp_motion("passive")
    end

    if (@window.button_down? Gosu::KbSpace) && !@window.pause_for_story
      if @artifact_to_shut_down != nil
        @artifact_to_shut_down.found = true
      end
    end
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
    @world_position[0] -= @window.world_motion[0]
    @world_position[1] -= @window.world_motion[1]

    @world_position[0] = @world_position[0]%WORLD_SIZE
    @world_position[1] = @world_position[1]%WORLD_SIZE
  end
  
  def damp_motion(motion)
    wM = @window.world_motion

    #active for when buttons are down, passive for when you're just hanging out
    case motion

      when "active"
        #enable cornering based on heading a nearly-cardinal direction
        if @angle.between?(340,359) || @angle.between?(0,10) || @angle.between?(170, 190)
          wM[0] *= 0.985
        elsif @angle.between?(260,280) || @angle.between?(80,100)
          wM[1] *= 0.985
        end

      when "passive"
        # reduce speed of the world unless it's already really small
        wM[0] *= 0.995 if wM[0].abs>0.05
        wM[1] *= 0.995 if wM[1].abs>0.05

        # spin slowly if the ship isn't being propelled through space
        if @window.world_motion[1] > 0
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
    #render engine particles
    @particle_array.each do |p|
      p.draw(@offset)
    end

    #render sonar waves
    if @show_sonar
      @sonar_array.each do |s|
        s.draw
      end
    end
    # 
    oX = @offset[0]
    oY = @offset[1]
    v = @vert
    ship_grey = @color
    white = ColorPicker.color('white')
    dark_grey = ColorPicker.color('dark_grey')

    @window.rotate(@angle, @vert['b'][0], @vert['b'][1]){
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