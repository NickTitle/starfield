#!/usr/bin/env ruby
require 'gosu'

WINDOW_WIDTH = 800
WINDOW_HEIGHT = 600
WIDTH = 640
HEIGHT = 480
WORLD_SIZE = 25000.0

class GameWindow < Gosu::Window
  attr_accessor :world_motion, :artifact_array, :radio
  attr_reader :ship

  def initialize
    super WINDOW_WIDTH, WINDOW_HEIGHT, false
    self.caption = "Starfield"
    @black = Gosu::Color.new(0xFF000000)
    @star_array = []
    @artifact_array = []
    @ship = Ship.new(self)
    @world_motion = [0.0,0.01];
    @minimap = Minimap.new(self, @ship)
    @writer = Writer.new(self)
    create_stars
    create_artifacts

    @radio = Radio.new(self, @ship, @artifact_array)

  end

  #create a set of stars for your ship to fly through
  def create_stars
    150.times do
      @star = Star.new(self)
      @star_array.push(@star)
    end
  end

  def create_artifacts
    11.times do
    # 16.times do
      @artifact = Artifact.new(self)
      @artifact_array.push(@artifact)
    end
  end

  def update
    @star_array.each do |star|
      star.update_position(@world_motion)
    end
    
    update_artifacts_in_range

    @ship.update
    @minimap.update
    @radio.update
    @writer.update
    exit if self.button_down? Gosu::KbEscape
  end

  def update_artifacts_in_range
    @artifact_array.each do |artifact|
      if (artifact.location[0]-@ship.world_position[0]).abs < 1.5*WIDTH && (artifact.location[1]-@ship.world_position[1]).abs < 1.5*HEIGHT
        artifact.update
        artifact.should_draw = true
      else
        artifact.should_draw = false
      end
    end
  end

  def draw
    self.scale(1.25, 1.25){
      
        #bottom row of stars
      @star_array.each do |s|
        s.draw unless s.z > 1.75
      end

        #flat layer, with artifacts and the ship
      @artifact_array.each do |a|
        a.draw unless !(a.should_draw && a.visible_on_map)
      end

      @ship.draw

        #top layer of stars
      @star_array.each do |s|
        s.draw unless s.z <= 1.75
      end

        #hud
      @minimap.draw
      @writer.draw
      @radio.draw
      
    }
  end
end

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

    if @window.button_down? Gosu::KbSpace then
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

class Star
  attr_accessor :x, :y, :z, :size
  def initialize(window)
    @window = window
    @x = rand(640)
    @y = rand(480)
    @z = (rand(25)/10.0)+1
    @size = ((rand(120)+1)/10.0)+0.5
    @rot = rand(90)
    @dir = [-1,1][rand(2)]*rand(100)/500.0
    @color = ColorPicker.color("white")
    @color = ColorPicker.color('random') if @z < 1.1 && @size < 13
  end

  def update_position(world_motion)
    @y += world_motion[1]*@z
    if @y < 0 || @y > 480
      reposition_star('x')
      @y%=480
    end
    
    @x += world_motion[0]*@z
    if @x < 0 || @x > 640
      reposition_star('y')
      @x%=640
    end

    @rot += @dir

  end

  def reposition_star(whichaxis)
    case whichaxis
      when 'x'
        @x = rand(640)
      when 'y'
        @y = rand(480)
    end
    @z = (rand(25)/10.0)+1
    @size = ((rand(150)+1)/10.0)+0.5
    @rot = rand(90)
    if @z < 1.1 && @size < 13
      @color = ColorPicker.color('random')
    else
      @color = ColorPicker.color('white')
    end
  end

  def draw

    xmin = @x-@size/2
    xmax = @x+@size/2
    ymin = @y-@size/2
    ymax = @y+@size/2
    s = @size
    color = @color
    @window.rotate(@rot, @x, @y){
      @window.draw_quad(
        xmin, ymin, color,
        xmax, ymin, color,
        xmin, ymax, color,
        xmax, ymax, color,
        0
      )  
    }
    
  end
end

class Particle
  attr_accessor :x, :y, :xvel, :yvel, :cycles, :max_cycles, :y_scalar, :angle, :origin, :color, :size

  def initialize(window, ship)
    @window = window
    @x = ship.vert['b'][0]
    @y = ship.vert['b'][1]
    @xvel = (rand(4)+1)-8
    @yvel = rand(8)+1
    @size = rand(3)+1
    @cycles = 0
    @max_cycles = 1.0
    @y_scalar = 0.2
    @color = Gosu::Color.new(0x00000000)
    @ship = ship
  end

  def update_position
    @x += @xvel
    @xvel = @xvel*0.7
    @y += @yvel
    @yvel = [@yvel*0.8, 0.1].max
    @cycles += 1

    ratio = @cycles/@max_cycles
    if ratio <= 0.2
      @color = ColorPicker.color('white')
    elsif ratio > 0.2 && ratio <= 0.4
      @color = ColorPicker.color('yellow')
    elsif ratio > 0.4 && ratio < 0.7
      @color = ColorPicker.color('orange')
    else
      @color = ColorPicker.color('red')
    end

    reset_particle unless @cycles < @max_cycles
  end

  def reset_particle
    if @window.button_down? Gosu::KbUp or @window.button_down? Gosu::GpUp then
      @y_scalar = 1.0
    else
      @y_scalar = [@y_scalar*0.7, 0.2].max
    end

    @x = @ship.vert['b'][0]
    @y = @ship.vert['b'][1]
    @xvel = ((rand(50)+1)/10.0-2.5) * y_scalar
    @yvel = rand(2)+8 * y_scalar
    @cycles = 0
    @max_cycles = (rand(40)+1.0) * y_scalar
    @angle = @ship.angle

  end

  def draw(offset)
    xmin = @x-@size/2+offset[0]
    xmax = @x+@size/2+offset[0]
    ymin = @y-@size/2+offset[1]
    ymax = @y+@size/2+offset[1]

    @window.rotate(@angle, @ship.vert['b'][0], @ship.vert['b'][1]){
      @window.draw_quad(
        xmin, ymin, @color,
        xmax, ymin, @color,
        xmin, ymax, @color,
        xmax, ymax, @color,
        0
      )
    }
  end
end

class Minimap
  def initialize(window, ship)
    @window = window
    @ship = ship
    @color = ColorPicker.color("map_background")
    @size = 100
    @offset = 10
    @cycle_count = 0
    @should_draw_ship = true
  end

  def update
    if @cycle_count >= 60
      @should_draw_ship = !@should_draw_ship 
      @cycle_count = 0
    else
      @cycle_count += 1
    end
  end

  def draw
    o = @offset
    s = @size
    c = @color

    @window.draw_quad(
      o, o, c,
      o+s, o, c,
      o+s, o+s, c,
      o, o+s, c,
      0
    )

    if @should_draw_ship
      c = ColorPicker.color("white")
      shipLoc = get_coords_for_position(@ship.world_position)
      
      x = o+shipLoc[0]
      y = o+shipLoc[1]

      @window.draw_quad(
        x, y, c,
        x, y+3, c,
        x+3, y+3, c,
        x+3, y, c,
        0
      )
    end

    @window.artifact_array.each do |a|
      if a.visible_on_map
        c = a.color
        loc = get_coords_for_position(a.location)
        x = o+loc[0]
        y = o+loc[1]

        @window.draw_quad(
          x, y, c,
          x, y+3, c,
          x+3, y+3, c,
          x+3, y, c,
          0
        )
      end
    end
  end

  def get_coords_for_position(position)
    x = position[0]/WORLD_SIZE * @size
    y = position[1]/WORLD_SIZE * @size
    return [x.round(2),y.round(2)]
  end
end

class Radio
  def initialize(window, ship, artifacts)
    
    @window = window
    @ship = ship
    @artifact_array = artifacts
    @radio_offset = 0
    
    static_sound_object = Gosu::Sample.new(window, "media/static.mp3")
    @static = static_sound_object.play(0,1,true)
    
    power_button_sound_object = Gosu::Sample.new(window, "media/button.mp3")
    @power_button = power_button_sound_object
    
    @reception_color = ColorPicker.color('white')
    @black = ColorPicker.color('black')
    @radio_grey = ColorPicker.color('radio_grey')
    @white = ColorPicker.color('white')
    
    @broadcast_range = 8
    @state = "off"

  end

  def update
    if @window.button_down? Gosu::KbComma
      @radio_offset -= 0.5 unless @radio_offset < 0.5
    end
    if @window.button_down? Gosu::KbPeriod
      @radio_offset += 0.5 unless @radio_offset > 274.5
    end

    if @radio_offset == 0
      @static.volume = 0
      @artifact_array.each do |a|
        a.broadcast.volume = 0
      end
        if @state == "on"
          @power_button.play(1,1,false)
          @state = "off"
        end
      return
    else
      if @state == "off"
        @power_button.play(1,1,false)
        @state = "on"
      end
    end

    artifacts_to_update = find_artifacts_in_broadcast_range

    if artifacts_to_update.length > 0
      @ship.show_sonar = true
      react_to_artifacts(artifacts_to_update)
    else
      @static.volume = 0.75
      @ship.show_sonar = false
    end
  end

  def find_artifacts_in_broadcast_range
    broadcasting_artifacts = []
  
    @artifact_array.each do |a|
      signal_closeness = (@radio_offset-a.frequency).abs
      signal_strength = @broadcast_range - signal_closeness
      if signal_closeness < @broadcast_range &&  broadcasting_artifacts.length < 2
        broadcasting_artifacts.push([a,distance(@ship.world_position, a.location), signal_strength])
      else
        a.broadcast.volume = 0
        a.visible_on_map = false
      end
    end

    #sort by signal strength
    broadcasting_artifacts.sort_by! { |x| x[2]}
  end

  def react_to_artifacts(artifacts)

      artifacts.each do |a|
        # artifact in question
        aIQ = a[0]
        
        signal_component = (0.6-0.6*(a[2]/(@broadcast_range)))
        distance_component = (0.45-0.45*(a[1]/(WORLD_SIZE)))
        broadcast_volume = (signal_component + distance_component)
        broadcast_volume = 1 if broadcast_volume > 1

        # let closest artifact set volumes, control sonar, etc
        if a == artifacts.first
          scaled_volume = (255*broadcast_volume).round
          @reception_color = ColorPicker.color('full_reception', scaled_volume)
          aIQ.visible_on_map = true
          aIQ.broadcast.volume = broadcast_volume
          aIQ.broadcast.volume = 0 if aIQ.found
          if a[1] < HEIGHT/2
            @static.volume = 0
            @ship.artifact_to_shut_down = aIQ
          else    
            @static.volume = (1-broadcast_volume) * 0.75
            @ship.artifact_to_shut_down = nil
          end

          @ship.sonar_array.each do |s|
            s.next_angle = angle(aIQ.location, @ship.world_position)
            @ship.countdown_max = 180 * 1-broadcast_volume + 20
          end
          7
        else
          # set radio volume for other elements, scaled by index in array
          aIQ.broadcast.volume = broadcast_volume * 0.2**artifacts.index(a)
        end
      end
  end

  def draw
    draw_behind_grill
    draw_grill
    draw_frame
    draw_dial_base
    draw_tuner
    draw_knobs
  end

  def draw_behind_grill
    bg = ColorPicker.color('white')
    c = @reception_color
    @window.draw_quad(
      11, HEIGHT-68, bg,
      139, HEIGHT-68, bg,
      139, HEIGHT, bg,
      11, HEIGHT, bg,
      0
    )
    @window.draw_quad(
      11, HEIGHT-68, bg,
      17, HEIGHT-73, bg,
      132, HEIGHT-73, bg,
      139, HEIGHT-68, bg,
      0
    )
  end

  def draw_grill
    t = 3  #thickness
    x = 19
    y = HEIGHT-65

    c1 = ColorPicker.color("radio_grey")
    c2 = ColorPicker.color("dark_grey")
    20.times do |i|
      12.times do |j|
       c = c1
       if i.between?(2,8) && j.between?(2,8)
          c = c2
        end
        @window.draw_quad(
          x+(t*2*i-t/2), y+(t*2*j-t/2), c,
          x+(t*2*i-t/2), y+(t*2*j+t/2), c,
          x+(t*2*i+t/2), y+(t*2*j+t/2), c,
          x+(t*2*i+t/2), y+(t*2*j-t/2), c,
          0
        )
      end
    end
  end

  def draw_frame
    t = 4
    h = 75
    w = 130
    x = 10
    y = HEIGHT - h
    c = ColorPicker.color('frame_blue')

      #left blue
    @window.draw_quad(
        x, y+2*t, c,
        x+t, y+2*t, c,
        x+t, y+h, c,
        x, y+h, c,
        0
      )

    #left angle
    @window.draw_quad(
        x, y+2*t, c,
        x+2*t, y, c,
        x+2*t, y+t, c,
        x+t, y+2*t, c,
        0
      )

      #top blue
    @window.draw_quad(
        x+2*t, y, c,
        x+2*t+(w-4*t), y, c,
        x+2*t+(w-4*t), y+t, c,
        x+2*t, y+t, c,
        0
      )

      #left angle
    @window.draw_quad(
        x+2*t+(w-4*t), y, c,
        x+w, y+2*t, c,
        x+w-t, y+2*t, c,
        x+2*t+(w-4*t), y+t, c,
        0
      )

      #right blue
    @window.draw_quad(
        x+w-t, y+2*t, c,
        x+w, y+2*t, c,
        x+w, y+h, c,
        x+w-t, y+h, c,
        0
      )
  end

  def draw_dial_base
    c = ColorPicker.color('dark_grey')
    c1 = ColorPicker.color('white')

    x = 85
    y = HEIGHT - 60
    size = 40

    draw_octagon(@window, x, y, size, c)

    draw_octagon(@window, x+2, y+2, size-4, c1)
    if @radio_offset > 0
      on_off_color = @reception_color
    else
      on_off_color = ColorPicker.color('radio_grey')
    end
    draw_octagon(@window, x+2, y+2, size-4, on_off_color) 
  end

  def draw_tuner
    x = 99
    y = HEIGHT-47
    s = 12.0
    white = ColorPicker.color("white")
    dark_grey = ColorPicker.color("dark_grey")
    dial = ColorPicker.color("dial_orange")
    @window.rotate((@radio_offset/275.0 * 180), x+s/2, y+s/2){
      draw_octagon(@window,x-1,y-1,s+2, dark_grey)
      draw_octagon(@window,x,y,s, white)    
      draw_octagon(@window,x-8,y+4, s/4, dial)
    }
    @window.draw_quad(
      x+2, y+17, dark_grey,
      x+11, y+17, dark_grey,
      x+11, y+18, dark_grey,
      x+2, y+18, dark_grey,
      0
    )
    @window.draw_quad(
      x+5, y+17, dial,
      x+8, y+17, dial,
      x+8, y+16, dial,
      x+5, y+16, dial,
      0
    )
  end

  def draw_knobs
    x = 94
    y = HEIGHT - 15
    s = 8
    black = ColorPicker.color('dark_grey')
    white = ColorPicker.color('white')
    dial = ColorPicker.color('dial_orange')
    left_knob_rotate = (@radio_offset > 0) ? 45 : 0
    @window.rotate(left_knob_rotate, x+s/2, y+s/2){
      draw_octagon(@window,x-1,y-1,s+2, black)
      draw_octagon(@window,x,y,s, white)    
      draw_octagon(@window,x+1,y, 2, dial)
    }
    x = 109
    @window.rotate(720*@radio_offset/275, x+s/2, y+s/2){
      draw_octagon(@window,x-1,y-1,s+2, black)
      draw_octagon(@window,x,y,s, white)    
      draw_octagon(@window,x-1, y+3, 2, dial)
    }
  end
end

class Artifact
  @@count = 0
  attr_accessor :location, :frequency, :broadcast, :found, :color, :should_draw, :visible_on_map
  def initialize(window)
    @@count += 1
    @window = window
    @color = ColorPicker.color('random')
    @tower_color = ColorPicker.color('random')
    @dir = rand(1)
    @dir = -1 if @dir == 0
    mp3_pick = @@count%7+1
    sound_obj = Gosu::Sample.new(window, "media/#{mp3_pick.to_s}.mp3")
    @broadcast = sound_obj.play(0,1,true)
    found_sound_obj = Gosu::Sample.new(window, "media/found_planet.mp3")
    @found_sound = found_sound_obj
    @visible_on_map = false
    @size_limits = [150+rand(25),400+rand(25)]
    @size = @size_limits[1]-@size_limits[0]
    @should_draw = false
    @expand = false
    @found = false
    @should_play_found = true
    @max_cycles_till_turned_off = 150+rand(60)
    @cycles_till_turned_off = @max_cycles_till_turned_off
    @flicker_draw = true

    debug = false
    if debug
      @rot = 0
      @frequency = 2
      @location = [WORLD_SIZE/2, WORLD_SIZE/2]
    else
      @rot = rand(180-90)
      @frequency = rand(275)
      @location = [rand(WORLD_SIZE), rand(WORLD_SIZE)]
    end
  end

  def update

    if @found == true
      @found_sound.play(1,1,false) unless @cycles_till_turned_off < @max_cycles_till_turned_off
      @cycles_till_turned_off -=1
      if @cycles_till_turned_off == 0
        @window.artifact_array.delete(self)
        return
      else
        @flicker_draw = @cycles_till_turned_off%10/7.0.round == 1 ? !@flicker_draw : @flicker_draw
      end
    end

    @rot += 0.015*@dir
    @rot%=360
  end

  def draw
    l = @location.dup
    s = @size
    l[0]+= (WIDTH/2 - @window.ship.world_position[0])-s/2
    l[1]+= (HEIGHT/2 - @window.ship.world_position[1])-s/2
    
    c = @color
    
    return if @flicker_draw == false
    @window.rotate(@rot, l[0]+s/2,l[1]+s/2){
      draw_octagon(@window,l[0], l[1],s, color)
      draw_tower(l,s,c)
    }    
  end

  def draw_tower(l,s,c)
    c1 = @tower_color
    lg = ColorPicker.color('radio_grey')
    dg = ColorPicker.color('dark_grey')
    b = ColorPicker.color('black')
    @window.draw_triangle(
      l[0]+s/4, l[1]+s/10, c1,
      l[0]+s/4+s/10, l[1]+s/10, c1,
      l[0]+s/2, l[1]-s*3/4, c1,
      0
    )
    @window.draw_triangle(
      s+l[0]-s/4, l[1]+s/10, c1,
      s+l[0]-(s/4+s/10), l[1]+s/10, c1,
      s+l[0]-s/2, l[1]-s*3/4, c1,
      0
    )

    #brace 1 left
    @window.draw_quad(
      l[0]+0.34*s, l[1]-0.12*s, c1,
      l[0]+0.36*s, l[1]-0.14*s, c1,
      l[0]+0.6*s, l[1]-0.21*s, c1,
      l[0]+0.62*s, l[1]-0.19*s, c1,
      0
    )
    #brace 1 right
    @window.draw_quad(
      l[0]+0.34*s, l[1]-0.21*s, c1,
      l[0]+0.36*s, l[1]-0.19*s, c1,
      l[0]+0.62*s, l[1]-0.12*s, c1,
      l[0]+0.64*s, l[1]-0.14*s, c1,
      0
    )

    #brace 2 left
    @window.draw_quad(
      l[0]+0.38*s, l[1]-0.32*s, c1,
      l[0]+0.40*s, l[1]-0.34*s, c1,
      l[0]+0.59*s, l[1]-0.38*s, c1,
      l[0]+0.61*s, l[1]-0.40*s, c1,
      0
    )
    #brace 2 right
    @window.draw_quad(
      l[0]+0.38*s, l[1]-0.38*s, c1,
      l[0]+0.40*s, l[1]-0.40*s, c1,
      l[0]+0.59*s, l[1]-0.32*s, c1,
      l[0]+0.61*s, l[1]-0.34*s, c1,
      0
    )

    
    x = l[0]+s*7/32
    y = l[1]+s*3/64
    w = s/6
    h = s/16
    #roof dimension
    rd = s/32
    #house base
    @window.draw_quad(
      x, y, lg,
      x+w, y, lg,
      x+w, y+h, lg,
      x, y+h, lg,
      0
    )
    #house roof
    @window.draw_quad(
      x-rd, y, dg,
      x+w+rd, y, dg,
      x+w, y-rd*3/2, dg,
      x, y-rd*3/2, dg,
      0
    )

    #door
    @window.draw_quad(
      x+w-2*rd, y+h, c1,
      x+w-rd, y+h, c1,
      x+w-rd, y+h*1/4, c1,
      x+w-2*rd, y+h*1/4, c1,
      0
    )    

    #window
    @window.draw_quad(
      x+rd, y+h*1/4, b,
      x+2*rd, y+h*1/4, b,
      x+2*rd, y+h/2, b,
      x+rd, y+h/2, b,
      0
    ) 

    draw_octagon(@window, s+l[0]-s/2-s/10,l[1]-s*3/4-s/10, s/5, c)
  end
end

class SonarBar
  attr_accessor :next_angle
  def initialize(window, ship, angle)
    @window = window
    @ship = ship
    @speed = 5
    @angle = angle
    @next_angle = 0
    @width = 2
    @trans = 0
    @center = @ship.vert['b']
    @x = @center[0]
    @y = @center[1]
    
  end

  def reset 
    @x = @center[0]
    @y = @center[1]
    @width = 2
    @trans = 255
    @speed = 5
    @angle = @next_angle
  end

  def update
    @width += 0.5
    @trans -= 5
    @speed *= 0.97
    @y += @speed
  end

  def draw
    return if @trans < 0.05
    x = @x
    y = @y
    w = @width
    c = ColorPicker.color('sonar', @trans.round)

    @window.rotate(@angle+rand(60)-30+90, @center[0], @center[1]) {
      @window.draw_quad(
        x-w/2, y, c,
        x-w/2, y+4, c,
        x+w/2, y+4, c,
        x+w/2, y, c,
        0
      )
    }
  end
end

class Writer
  attr_accessor
  def initialize(window)
    @window = window
    @font = Gosu::Font.new(window, "media/04B03.TTF", 24)
    @text = "There's nobody in this one, either..."
    type_sound_1 = Gosu::Sample.new(window, "./media/type1.mp3")
    type_sound_2 = Gosu::Sample.new(window, "./media/type2.mp3")
    type_sound_3 = Gosu::Sample.new(window, "./media/type3.mp3")
    @type_sound = [type_sound_1, type_sound_2, type_sound_3]
    @scan = 1
    @post_scan_timer_checks = 30
    @timer = 10
    @x = 150
    @y = HEIGHT - 25
    @trans = ColorPicker.color('map_background')
    @repeat = false
  end

  def set_text(text)
    @repeat = false
    @text = text
    @scan = 0
  end

  def update
    @timer -=1
    if @timer <=0
      @scan += 1
      @type_sound[rand(3)].play(1,1, false) unless @repeat
      @scan = 0 if @scan > @text.length
      
      if @scan == @text.length
        @timer = 3*@post_scan_timer_checks
        @repeat = true
      else
        @timer = 2
      end

    end
  end

  def draw
    t = @trans
    @window.draw_quad(
      0, @y, t,
      WIDTH, @y, t,
      WIDTH, HEIGHT, t,
      0, HEIGHT, t,
      0
    )
    @font.draw(@text[0, @scan], @x, @y, 0)
  end
end

class ColorPicker
  color_string = 0
    def self.color(name, trans = 255)
      case name
        when "red"
          color_string = 0xFFFF0000
        when "orange"
          color_string = 0xFFFF9900
        when "yellow"
          color_string = 0xFFFFFF00
        when "green"
          color_string = 0xFF00FF00
        when "blue"
          color_string = 0xFF0000FF
        when "purple"
          color_string = 0xFFFF00FF
        when "white"
          color_string = 0xFFFFFFFF
        when "black"
          color_string = 0xFF000000
        when "ship_grey"
          color_string = 0xFF6E6E6E
        when "radio_grey"
          color_string = 0xFF8E8E8E
        when "dark_grey"  
          color_string = 0xFF3E3E3E
        when "map_background"
          color_string = 0x33FFFFFF
        when "grill_grey"
          color_string = 0xFFEBEBEB
        when "frame_blue"
          color_string = 0xFF3885D1
        when "dial_orange"
          color_string = 0xFFFF7735
        when "random"
          color_string = ("0xFF"+rand(0xFFFFFF).to_s(16).upcase).to_i(16)
        when "full_reception"
          c = trans.to_s(16).upcase
          color_string = ("0x"+c+"FFFFCC").to_i(16)
        when "sonar"
          c = trans.to_s(16).upcase
          color_string = ("0x"+c+"63ADD0").to_i(16)
        end

      Gosu::Color.new(color_string)
    end
end

def distance(a,b)
  ((b[0]-a[0])**2 + (b[1]-a[1])**2)**0.5
end

def angle(a,b)
  Math.atan2(b[1]-a[1],b[0]-a[0]) * 180 / Math::PI
end

#draw octagon with top-left coords of x,y and diameter of size
def draw_octagon(window, x, y, size, color)
  window.draw_quad(
      x, y+size/4, color,
      x+size/4, y, color,
      x+size*3/4, y, color,
      x+size, y+size/4, color,
      0
    )
  window.draw_quad(
      x, y+size*3/4, color,
      x+size/4, y+size, color,
      x+size*3/4, y+size, color,
      x+size, y+size*3/4, color,
      0
    )
  window.draw_quad(
      x, y+size/4, color,
      x+size, y+size/4, color,
      x+size, y+size*3/4, color,
      x, y+size*3/4, color,
      0
    )
end

window = GameWindow.new
window.show