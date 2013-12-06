require 'gosu'

class GameWindow < Gosu::Window
  attr_accessor :world_motion
  attr_reader :ship
  def initialize
    super 640,480, false
    self.caption = "Starfield"
    @black = Gosu::Color.new(0xFF000000)
    @star_array = []
    @ship = Ship.new(self)
    @world_motion = [0.0,0.01];

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
  end

  def draw
    @star_array.each do |s|
      s.draw unless s.z > 1.75
    end

    @ship.draw

    @star_array.each do |s|
      s.draw unless s.z <= 1.75
    end
  end

end

class Ship
  attr_accessor :offset, :offset_counter, :angle, :vert
  
  def initialize(window)
    @window = window
    @vert = {'t' => [320,230], 'l' => [310, 265], 'r' =>[330, 265], 'b' =>[320,260]}
    @offset = [0,0]
    @offset_counter = [0,0]
    @angle = 0
    @particle_array = []
    @color = ColorPicker.color('ship_grey')

    create_particles

  end

  def create_particles
    100.times do
      @particle = Particle.new(@window, self)
      @particle_array.push(@particle)
    end
  end

  def update
    update_offset
    @particle_array.each do |p|
      p.update_position
    end

    check_keyboard

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
    end

  end

  def update_offset
    @offset_counter[1] += 0.01
    @offset_counter[1]=@offset_counter[1]%90
    @offset[1] = 30*Math.sin(@offset_counter[1]);
    @offset_counter[0]+=0.005
    @offset_counter[0]=@offset_counter[0]%90
    @offset[0] = 150*Math.sin(@offset_counter[0]);
    @offset=[0,0]
  end

  def draw
    

      @particle_array.each do |p|
        p.draw(@offset)
      end

      oX = @offset[0]
      oY = @offset[1]
      v = @vert

    @window.rotate(@angle, @vert['b'][0], @vert['b'][1]){

        @window.draw_triangle(
          v['t'][0]+oX, v['t'][1]+oY, @color,
          v['l'][0]+oX, v['l'][1]+oY, @color,
          v['b'][0]+oX, v['b'][1]+oY, @color,
          0
        )
        @window.draw_triangle(
          v['t'][0]+oX, v['t'][1]+oY, @color,
          v['r'][0]+oX, v['r'][1]+oY, @color,
          v['b'][0]+oX, v['b'][1]+oY, @color,
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
    @size = rand(15)+1
  end

  def update_position(world_motion)
    @y += world_motion[1]*@z
    @y = @y%480
    @x += world_motion[0]*@z
    @x = @x%640
  end

  def draw

    xmin = @x-@size/2
    xmax = @x+@size/2
    ymin = @y-@size/2
    ymax = @y+@size/2
    color = ColorPicker.color('white')

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
        end

      Gosu::Color.new(color_string) 
    end
end

window = GameWindow.new
window.show
