
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
    @center = @ship.sonar_origin
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