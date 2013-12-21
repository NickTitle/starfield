class Writer
  attr_reader :text
  def initialize(window)
    @window = window
    @font = Gosu::Font.new(window, "media/04B03.TTF", 18)
    @big_font = Gosu::Font.new(window, "media/04B03.TTF", 165)
    @text = ""
    type_sound_1 = Gosu::Sample.new(window, "./media/type1.mp3")
    type_sound_2 = Gosu::Sample.new(window, "./media/type2.mp3")
    type_sound_3 = Gosu::Sample.new(window, "./media/type3.mp3")
    @type_sound = [type_sound_1, type_sound_2, type_sound_3]
    @scan = 1
    @post_scan_timer_checks = 60
    @timer = 10
    @x = 150
    @y = HEIGHT - 20
    @trans = ColorPicker.color('writer_background')
    @repeat = false
  end

  def set_text=(text)
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
    @font.draw(@text[0, @scan], @x, @y+1, 0, 1, 1, ColorPicker.color('dark_grey'), :default)
  end

  def draw_title
    @big_font.draw("Starfield", 18, 10, 0, 1, 1, ColorPicker.color('white'), :default)
    
    if @window.end_screen_transparency == 0
      @font.draw("Press SPACE to begin", 225, 170, 0, 1, 1, ColorPicker.color('white'), :default)
    end
  end

end