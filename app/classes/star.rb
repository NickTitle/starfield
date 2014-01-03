class Star
  attr_accessor :x, :y, :z, :size
  def initialize(window)
    @window = window
    @ship = @window.ship
    @x = rand(640)
    @y = rand(480)
    @z = (rand(25)/10.0)+1
    @size = ((rand(150)+1)/10.0)+0.5
    @rot = rand(90)
    @dir = [-1,1][rand(2)]*rand(100)/500.0
    @color = ColorPicker.color("star_white")
    @color = ColorPicker.color('star_random') if @z < 1.1 && @size < 13
    @border = ColorPicker.color('star_black')
  end

  def update_position(world_motion)
    @y += -1*@ship.velocity[1]*@z
    if @y < 0 || @y > 480
      reposition_star('x')
      @y%=480
    end

    @x += -1*@ship.velocity[0]*@z
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
      @color = ColorPicker.color('star_random')
    else
      @color = ColorPicker.color('star_white')
    end
  end

  def draw

    xmin = @x-@size/2
    xmax = @x+@size/2
    ymin = @y-@size/2
    ymax = @y+@size/2
    s = @size
    color = @color
    b = @border
    @window.rotate(@rot, @x, @y){
      @window.draw_quad(
        xmin-1, ymin-1, b,
        xmax+1, ymin-1, b,
        xmin-1, ymax+1, b,
        xmax+1, ymax+1, b,
        0
      )
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
