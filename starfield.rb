require 'gosu'

WIDTH = 800
HEIGHT = 600
WORLD_SIZE = 10000

class GameWindow < Gosu::Window
  attr_accessor :world_motion
  attr_reader :ship

  def initialize
    super WIDTH, HEIGHT, false
    self.caption = "Starfield"
    @black = Gosu::Color.new(0xFF000000)
    @star_array = []
    @ship = Ship.new(self)
    @world_motion = [0.0,0.01];
    @minimap = Minimap.new(self, @ship)
    create_stars
  end

  def create_stars
    200.times do
      @star = Star.new(self)
      @star_array.push(@star)
    end
  end

  def update
    @star_array.each do |star|
      star.update_position(@world_motion)
    end
    @ship.update
    @minimap.update
  end

  def draw
    self.scale(1.25, 1.25){
      @star_array.each do |s|
        s.draw unless s.z > 1.75
      end

      @ship.draw

      @star_array.each do |s|
        s.draw unless s.z <= 1.75
      end

      @minimap.draw
    }
  end

end

class Ship
  attr_accessor :offset, :offset_counter, :angle, :vert, :engine_sound, :current_engine_volume, :world_position
  
  def initialize(window)
    @window = window
    @vert = {'t' => [320,230], 'l' => [310, 265], 'r' =>[330, 265], 'b' =>[320,260]}
    @offset = [0,0]
    @offset_counter = [0,0]
    @angle = 0
    @particle_array = []
    @color = ColorPicker.color('ship_grey')
    sound_obj = Gosu::Sample.new(window, "media/engine2.wav")
    @engine_sound = sound_obj.play(0,1,true)
    @current_engine_volume = 0
    @world_position = [WORLD_SIZE/2, WORLD_SIZE/2]
    create_particles

  end

  def create_particles
    100.times do
      @particle = Particle.new(@window, self)
      @particle_array.push(@particle)
    end
  end

  def update
    # update_offset
    @particle_array.each do |p|
      p.update_position
    end

    check_keyboard

    position_in_world

  end

  def check_keyboard
    wM = @window.world_motion
    if @window.button_down? Gosu::KbLeft or @window.button_down? Gosu::GpLeft then
      @angle = (@angle-2)%360
    end
    if @window.button_down? Gosu::KbRight or @window.button_down? Gosu::GpRight then
      @angle = (@angle+2)%360
    end
    if @window.button_down? Gosu::KbUp or @window.button_down? Gosu::GpUp then
      # @window.world_motion[0]+= Math.cos(@angle)
      radAngle = @angle*Math::PI/180
      wM[1] = [ [4, wM[1]+0.01*Math.cos(radAngle)].min, -4].max
      wM[0] = [ [4, wM[0]-0.01*Math.sin(radAngle)].min, -4].max

      @engine_sound.volume=(1)
      @current_engine_volume = 1

    else

      if @current_engine_volume > 0
        @current_engine_volume *= 0.95
        @current_engine_volume = 0 unless @current_engine_volume > 0.05
        @engine_sound.volume = @current_engine_volume
      end

      if @window.world_motion[1]>0
        @angle = @angle-0.1%360
      else
        @angle = @angle+0.1%360
      end
        @window.world_motion[0] *= 0.995
        @window.world_motion[1] *= 0.995
    end
  end

  def position_in_world
    @world_position[0] -= @window.world_motion[0]
    @world_position[1] -= @window.world_motion[1]

      @world_position.each do |coord|
        coord = coord%10000
      end
  end

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

      @particle_array.each do |p|
        p.draw(@offset)
      end

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

  end

  def reposition_star(whichaxis)
    case whichaxis
      when 'x'
        @x = rand(640)
      when 'y'
        @y = rand(480)
    end
    @size = ((rand(150)+1)/10.0)+0.5
  end

  def draw

    xmin = @x-@size/2
    xmax = @x+@size/2
    ymin = @y-@size/2
    ymax = @y+@size/2
    s = @size
    color = ColorPicker.color('white')

    if @z < 1.1
        if s < 9 && s > 7
        color = ColorPicker.color('blue')
        elsif s <=7 && s > 4
          color = ColorPicker.color('green')
        elsif s <=4 && s > 2
          color = ColorPicker.color('orange')
        elsif s <2
          color = ColorPicker.color('red')
        end
    end

    @window.draw_quad(
      xmin, ymin, color,
      xmax, ymin, color,
      xmin, ymax, color,
      xmax, ymax, color,
      0
    )
  end
end

class Particle
  attr_accessor :x, :y, :xvel, :yvel, :cycles, :max_cycles, :y_scalar, :angle, :origin, :color, :size

  def initialize(window, ship)
    @window = window
    @x = 320
    @y = 260
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
    @xvel = [@xvel*0.75, 0.1].max
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

    @x = 320  
    @y = 260 
    @xvel = (rand(41)/10.0-2.0) * y_scalar
    @yvel = (10-@xvel.abs/2.0) * y_scalar
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
    @offset = 5
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
      shipLoc = get_ship_coords_for_map
      
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

  end

  def get_ship_coords_for_map
    x = @ship.world_position[0]/WORLD_SIZE * @size
    y = @ship.world_position[1]/WORLD_SIZE * @size
    return [x.round(2),y.round(2)]
  end

end

class ColorPicker
  color_string = 0
    def self.color(name)
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
        when "dark_grey"  
          color_string = 0xFF3E3E3E
        when "map_background"
          color_string = 0x33FFFFFF
        end

      Gosu::Color.new(color_string) 
    end
end

window = GameWindow.new
window.show
