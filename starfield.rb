require 'gosu'

class GameWindow < Gosu::Window

  @color = 'black'

  def initialize
    super 640,480, false
    self.caption = "Starfield"
    @black = Gosu::Color.new(0xFF000000)
    @white = Gosu::Color.new(0xFFFFFFFF)
    @red = Gosu::Color.new(0xFFFF0000)
    @orange = Gosu::Color.new(0xFFFF9900)
    @shipGrey = Gosu::Color.new(0xFF6E6E6E)
    @starArray = []
    @particleArray = []
    @shipOffsetXCounter = 0
    @shipOffsetX = 0
    @shipOffsetYCounter = 0
    @shipOffsetY = 0

    create_stars()
    create_particles()
  end

  def update
    @starArray.each do |star|
      star.update_position
    end
    @particleArray.each do |particle|
      particle.update_position
    end

    @shipOffsetYCounter+=0.01
    @shipOffsetYCounter=@shipOffsetYCounter%90
    @shipOffsetY = 30*Math.sin(@shipOffsetYCounter);
    @shipOffsetXCounter+=0.005
    @shipOffsetXCounter=@shipOffsetXCounter%90
    @shipOffsetX = 150*Math.sin(@shipOffsetXCounter);

  end

  def draw
    @starArray.each do |s|
    draw_stars(s.x, s.y, s.size) unless s.z > 1.75
    end

    @particleArray.each do |p|
    draw_particles(p.x+@shipOffsetX, p.y+@shipOffsetY, p.size, p.color)
    end

    draw_ship()

    @starArray.each do |s|
    draw_stars(s.x, s.y, s.size) unless s.z <= 1.75
    end
    
  end

  def create_stars
    200.times do
      @star = Star.new(self)
      @starArray.push(@star)
    end
  end

  def create_particles
    100.times do
      @particle = Particle.new(self)
      @particleArray.push(@particle)
    end
  end

  def draw_stars(x, y, size)

    xmin = x-size/2
    xmax = x+size/2
    ymin = y-size/2
    ymax = y+size/2

    draw_quad(
      xmin, ymin, @white,
      xmax, ymin, @white,
      xmin, ymax, @white,
      xmax, ymax, @white,
      0
    )
  end

  def draw_particles(x, y, size, color)
    xmin = x-size/2
    xmax = x+size/2
    ymin = y-size/2
    ymax = y+size/2

    draw_quad(
      xmin, ymin, color,
      xmax, ymin, color,
      xmin, ymax, color,
      xmax, ymax, color,
      0
    )
  end

  def draw_ship
    draw_triangle(
      320+@shipOffsetX, 230+@shipOffsetY, @shipGrey,
      310+@shipOffsetX, 265+@shipOffsetY, @shipGrey,
      320+@shipOffsetX, 260+@shipOffsetY, @shipGrey,
      0
    )
    draw_triangle(
      320+@shipOffsetX, 230+@shipOffsetY, @shipGrey,
      330+@shipOffsetX, 265+@shipOffsetY, @shipGrey,
      320+@shipOffsetX, 260+@shipOffsetY, @shipGrey,
      0
    )
  end
end

class Star
  attr_accessor :x, :y, :z, :size
  def initialize(window)
    self.x = rand(640)
    self.y = rand(480)
    self.z = (rand(25)/10.0)+1
    self.size = rand(15)+1
  end

  def update_position
    self.y += self.z
    self.y -= 480 unless self.y < 480
  end
end

class Particle
  attr_accessor :x, :y, :xvel, :yvel, :cycles, :maxCycles, :color, :size
  def initialize(window)
    self.x = 320
    self.y = 260
    self.xvel = (rand(4)+1)-8
    self.yvel = rand(8)+1
    self.size = rand(2)+1
    self.cycles = 0
    self.maxCycles = rand(30)+1.0
    self.color = ColorPicker.color('red')
  end

  def update_position
    self.x += self.xvel
    self.xvel = xvel*0.7
    self.y += self.yvel
    self.yvel = yvel*0.8
    self.cycles += 1

    ratio = self.cycles/self.maxCycles
    if ratio <= 0.2
      self.color = ColorPicker.color('white')
    elsif ratio > 0.2 && ratio <= 0.4
      self.color = ColorPicker.color('yellow')
    elsif ratio > 0.4 && ratio < 0.7
      self.color = ColorPicker.color('orange')
    else
      self.color = ColorPicker.color('red')
    end

    unless(self.cycles < self.maxCycles)
      self.x = 320
      self.y = 260 
      self.xvel = (rand(40)-20)/10.0
      self.yvel = 10-xvel.abs
      self.cycles = 0
      self.maxCycles = rand(30)+1.0
      # self.xvel *= 0.8 unless self.yvel < 3
    end

  end
end

class ColorPicker
  colorString = 0
    def self.color(name)
      case name
        when "red"
          colorString = 0xFFFF0000
        when "orange"
          colorString = 0xFFFF9900
        when "yellow"
          colorString = 0xFFFFFF00
        when "green"
          colorString = 0xFF00FF00
        when "blue"
          colorString = 0xFF0000FF
        when "purple"
          colorString = 0xFFFF00FF
        when "white"
          colorString = 0xFFFFFFFF
        end
      Gosu::Color.new(colorString) 
    end
end

window = GameWindow.new
window.show
