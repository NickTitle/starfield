class Writer
  attr_reader :text
  def initialize(window)
    @window = window
    @font = Gosu::Font.new(window, "media/04B03.TTF", 18)
    @big_font = Gosu::Font.new(window, "media/04B03.TTF", 165)
    @text = ""
    type_sound_1 = Gosu::Sample.new(window, "./media/sfx/type1.mp3")
    type_sound_2 = Gosu::Sample.new(window, "./media/sfx/type2.mp3")
    type_sound_3 = Gosu::Sample.new(window, "./media/sfx/type3.mp3")
    @type_sound = [type_sound_1, type_sound_2, type_sound_3]
    @scan = 1
    @post_scan_timer_checks = 60
    @timer = 10
    @x = 150
    @y = HEIGHT - 20
    @trans = ColorPicker.color('writer_background')
    @repeat = false
    @space_alert_timer = 120
    @show_space_alert = true
  end

  def set_text=(text)
    @repeat = false
    @scan = 0
    @timer = 10
    @text = text
  end

  def update

    @timer -=1
    if @timer <=0
      @scan += 1
      @type_sound[rand(3)].play(1,1, false) unless (@repeat || @text.length == 0)
      @scan = 0 if @scan > @text.length

      if @scan == @text.length
        @timer = 3*@post_scan_timer_checks
        @repeat = true
      else
        @timer = 2
      end
    end
    @space_alert_timer -=1
    if @space_alert_timer <=0
      @show_space_alert = !@show_space_alert
      if @show_space_alert
        @space_alert_timer = 60 
      else
        @space_alert_timer = 20
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

    if @window.pause_for_story
      @window.draw_quad(
        7/8.0*WIDTH, @y-20, t,
        WIDTH, @y-20, t,
        WIDTH, @y, t,
        7/8.0*WIDTH, @y, t,
        0
      )
      if @show_space_alert
        @font.draw("*SPACE*", 7/8.0*WIDTH+10, @y-18, 0, 1, 1, ColorPicker.color('dark_grey'), :default)
      end
    end
  end

  def draw_title
    @big_font.draw("Starfield", 18, 10, 0, 1, 1, ColorPicker.color('white'), :default)

    if @window.end_screen_transparency == 0
      @font.draw("Press SPACE to begin", 225, 170, 0, 1, 1, ColorPicker.color('white'), :default)
    end
  end

end
