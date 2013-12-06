require 'gosu'

class GameWindow < Gosu::Window

	@color = 'black'

	def initialize
		super 640,480, false
		self.caption = "Starfield"
		@black = Gosu::Color.new(0xFF000000)
		@white = Gosu::Color.new(0xFFFFFFFF)
		@starArray = []
		
		createStars()
	end

	def update
		@starArray.each do |star|
			star.updatePosition
		end
	end

	def draw
		@starArray.each do |s|
			
			size = s.size
			x = s.x
			y = s.y

			xmin = x-size/2
			xmax = x+size/2
			ymin = y-size/2
			ymax = y+size/2

			draw_quad(
			xmin, ymin, @white,
			xmax, ymin, @white,
			xmin, ymax, @white,
			xmax, ymax, @white,
			0)

		end
		
	end

	def createStars
		200.times do
			@star = Star.new(self)
			@starArray.push(@star)
		end
	end


end

class Star
	attr_accessor :x, :y, :z, :size
	def initialize(window)
		self.x = rand(640)
		self.y = rand(480)
		self.z = (rand(30)/10)+1
		self.size = rand(15)+1
	end

	def updatePosition
		self.y += self.z
		self.y -= 480 unless self.y < 480
	end
end

window = GameWindow.new
window.show
