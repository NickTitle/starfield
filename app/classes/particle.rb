class Particle
  attr_accessor :x, :y, :xvel, :yvel, :cycles, :max_cycles, :y_scalar, :angle, :origin, :color, :size

  def initialize(window, ship)
    @window = window
    @origin = ship.particle_origin
    @x = ship.particle_origin[0]
    @y = ship.particle_origin[1]
    @xvel = (rand(3.0)+1)-1.5
    @yvel = rand(3)+1
    @size = rand(3)+1
    @cycles = 0
    @max_cycles = 1.0
    @y_scalar = 0.2
    @color = Gosu::Color.new(0x00000000)
    @ship = ship
  end

  def update_position(up = false)
    @x += @xvel
    @xvel = @xvel*0.9
    @y += @yvel
    # @yvel *= 0.8 if @yvel > 3
    # @yvel = [@yvel*0.8, 0.1].max
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

    reset_particle(up) unless @cycles < @max_cycles
  end

  def reset_particle(up)
    if (!@window.pause_for_story && up) || ([0,4].include?@window.game_state)
      @y_scalar = @ship.current_engine_volume
    else
      @y_scalar = [@y_scalar*0.7, 0.2].max
    end

    @x = @origin[0]
    @y = @origin[1]
    @xvel = ((rand(30)+1)/10.0-1.5) * y_scalar
    @yvel = rand(2)+2 * y_scalar
    @cycles = 0
    @max_cycles = (rand(80)+1.0) * y_scalar
    @angle = @ship.angle

  end

  def draw(offset)
    xmin = @x-@size/2+offset[0]
    xmax = @x+@size/2+offset[0]
    ymin = @y-@size/2+offset[1]
    ymax = @y+@size/2+offset[1]

    @window.rotate(@angle, origin[0], origin[1]){
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
