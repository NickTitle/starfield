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
		draw_stars(s.x, s.y, s.size)
		end

		@particleArray.each do |p|
		draw_particles(p.x+@shipOffsetX, p.y+@shipOffsetY, p.size)
		end

		draw_ship()
		
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

	def draw_particles(x, y, size)
		xmin = x-size/2
		xmax = x+size/2
		ymin = y-size/2
		ymax = y+size/2

		draw_quad(
			xmin, ymin, @red,
			xmax, ymin, @red,
			xmin, ymax, @orange,
			xmax, ymax, @orange,
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
		self.z = (rand(25)/10)+1
		self.size = rand(15)+1
	end

	def update_position
		self.y += self.z
		self.y -= 480 unless self.y < 480
	end
end

class Particle
	attr_accessor :x, :y, :xvel, :yvel, :size
	def initialize(window)
		self.x = 320
		self.y = 260
		self.xvel = (rand(4)+1)-8
		self.yvel = rand(8)+1
		self.size = rand(2)+1
	end

	def update_position
		self.x += self.xvel
		self.xvel = xvel*0.9
		self.y += self.yvel
		self.yvel = yvel*0.8

		unless((self.xvel).abs>0.05 && (self.yvel).abs>0.1)
			self.x = 320
			self.y = 260 
			self.xvel = (rand(40)-20)/10
			self.yvel = rand(7)+4
			self.xvel *= 0.5 unless self.yvel < 3
		end

	end
end

# class Spaceship
# 	attr_accessor :
# end

window = GameWindow.new
window.show
