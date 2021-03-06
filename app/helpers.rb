class ColorPicker
  color_string = 0
    def self.color(name, trans = 255)
      case name
        when "red"
          color_hex_value = 0xFFFF0000
        when "orange"
          color_hex_value = 0xFFFF9900
        when "yellow"
          color_hex_value = 0xFFFFFF00
        when "green"
          color_hex_value = 0xFF00FF00
        when "blue"
          color_hex_value = 0xFF0000FF
        when "purple"
          color_hex_value = 0xFFFF00FF
        when "white"
          color_hex_value = 0xFFFFFFFF
        when "star_white"
          color_hex_value = 0x66FFFFFF
        when "star_random"
          color_hex_value = ("0x55" + rand_hex_rgb).to_i(16)
        when "star_black"
          color_hex_value = 0x55000000
        when "black"
          color_hex_value = 0xFF000000
        when "ship_grey"
          color_hex_value = 0xFF6E6E6E
        when "radio_grey"
          color_hex_value = 0xFF8E8E8E
        when "dark_grey"  
          color_hex_value = 0xFF3E3E3E
        when "map_background"
          color_hex_value = 0x88FFFFFF
        when "writer_background" 
          color_hex_value = 0xBBFFFFFF
        when "grill_grey"
          color_hex_value = 0xFFEBEBEB
        when "frame_blue"
          color_hex_value = 0xFF3885D1
        when "dial_orange"
          color_hex_value = 0xFFFF7735
        when "ship_orange"
          color_hex_value = 0xFFE98820
        when "space"
          color_hex_value = 0xFF070B1B
        when "patch_brown"
          color_hex_value = 0xFF322611
        when "patch_green"
          color_hex_value = 0xFF2D940A
        when "ship_peach"
          color_hex_value = 0xFFF5D04C
        when "random"
          color_hex_value = ("0xFF" + rand_hex_rgb).to_i(16)
        when "random_grey"
          grey_seed_1 = rand(0xF).to_s(16)
          grey_seed_2 = rand(0xF).to_s(16)
          grey_seed = grey_seed_1 + grey_seed_2
          color_hex_value = ("0xFF" + grey_seed + grey_seed + grey_seed).to_i(16)
        when "full_reception"
          c = trans.to_s(16).upcase
          color_hex_value = ("0x"+c+"FFFFCC").to_i(16)
        when "sonar"
          c = trans.to_s(16).upcase
          color_hex_value = ("0x"+c+"63ADD0").to_i(16)
        when "fade_out"
          c = trans.to_s(16).upcase
          color_hex_value = ("0x"+c+"000000").to_i(16)
        end

      Gosu::Color.new(color_hex_value)
    end
end

def rand_hex_rgb
  hex_string = ""
  6.times do
    hex = rand(0xf).to_s(16)
    hex_string << hex
  end
  hex_string
end

def distance(a,b)
  ((b[0]-a[0])**2 + (b[1]-a[1])**2)**0.5
end

def get_angle(a,b)
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
