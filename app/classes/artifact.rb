class Artifact
  @@count = 0
  attr_accessor :location, :frequency, :broadcast, :found, :color, :should_draw, :visible_on_map
  def initialize(window)
    @@count += 1
    @window = window
    @color = ColorPicker.color('random')
    @tower_color = ColorPicker.color('random')
    @dir = rand(1)
    @dir = -1 if @dir == 0
    mp3_pick = @@count%7+1
    sound_obj = Gosu::Sample.new(window, "media/#{mp3_pick.to_s}.mp3")
    @broadcast = sound_obj.play(0,1,true)
    found_sound_obj = Gosu::Sample.new(window, "media/found_planet.mp3")
    @found_sound = found_sound_obj
    @visible_on_map = false
    @size_limits = [150+rand(25),400+rand(25)]
    @size = @size_limits[1]-@size_limits[0]
    @should_draw = false
    @expand = false
    @found = false
    @should_play_found = true
    @max_cycles_till_turned_off = 150+rand(60)
    @cycles_till_turned_off = @max_cycles_till_turned_off
    @flicker_draw = true

    if DEBUG
      @rot = 0
      @frequency = 2
      @location = [WORLD_SIZE/2, WORLD_SIZE/2]
    else
      @rot = rand(180-90)
      @frequency = rand(275)
      @location = [rand(WORLD_SIZE), rand(WORLD_SIZE)]
    end
  end

  def update

    if @found == true
      @tower_color = ColorPicker.color('random')
      @color = ColorPicker.color('random')
      @found_sound.play(1,1,false) unless @cycles_till_turned_off < @max_cycles_till_turned_off
      @cycles_till_turned_off -=1
      if @cycles_till_turned_off == 0
        @window.ship.artifact_to_shut_down = nil
        @window.artifact_array.delete(self)
        @window.update_story unless DEBUG
        @@count-=1
        return
      else
        @flicker_draw = @cycles_till_turned_off/2%10/6.0.round == 1 ? !@flicker_draw : @flicker_draw
      end
    end

    @rot += 0.015*@dir
    @rot%=360
  end

  def draw
    l = @location.dup
    s = @size
    l[0]+= (WIDTH/2 - @window.ship.location[0])-s/2
    l[1]+= (HEIGHT/2 - @window.ship.location[1])-s/2
    
    c = @color
    
    return if @flicker_draw == false
    @window.rotate(@rot, l[0]+s/2,l[1]+s/2){
      draw_octagon(@window,l[0], l[1],s, color)
      draw_tower(l,s,c)
    }    
  end

  def draw_tower(l,s,c)
    c1 = @tower_color
    lg = ColorPicker.color('radio_grey')
    dg = ColorPicker.color('dark_grey')
    b = ColorPicker.color('black')
    @window.draw_triangle(
      l[0]+s/4, l[1]+s/10, c1,
      l[0]+s/4+s/10, l[1]+s/10, c1,
      l[0]+s/2, l[1]-s*3/4, c1,
      0
    )
    @window.draw_triangle(
      s+l[0]-s/4, l[1]+s/10, c1,
      s+l[0]-(s/4+s/10), l[1]+s/10, c1,
      s+l[0]-s/2, l[1]-s*3/4, c1,
      0
    )

    #brace 1 left
    @window.draw_quad(
      l[0]+0.34*s, l[1]-0.12*s, c1,
      l[0]+0.36*s, l[1]-0.14*s, c1,
      l[0]+0.6*s, l[1]-0.21*s, c1,
      l[0]+0.62*s, l[1]-0.19*s, c1,
      0
    )
    #brace 1 right
    @window.draw_quad(
      l[0]+0.34*s, l[1]-0.21*s, c1,
      l[0]+0.36*s, l[1]-0.19*s, c1,
      l[0]+0.62*s, l[1]-0.12*s, c1,
      l[0]+0.64*s, l[1]-0.14*s, c1,
      0
    )

    #brace 2 left
    @window.draw_quad(
      l[0]+0.38*s, l[1]-0.32*s, c1,
      l[0]+0.40*s, l[1]-0.34*s, c1,
      l[0]+0.59*s, l[1]-0.38*s, c1,
      l[0]+0.61*s, l[1]-0.40*s, c1,
      0
    )
    #brace 2 right
    @window.draw_quad(
      l[0]+0.38*s, l[1]-0.38*s, c1,
      l[0]+0.40*s, l[1]-0.40*s, c1,
      l[0]+0.59*s, l[1]-0.32*s, c1,
      l[0]+0.61*s, l[1]-0.34*s, c1,
      0
    )

    
    x = l[0]+s*7/32
    y = l[1]+s*3/64
    w = s/6
    h = s/16
    #roof dimension
    rd = s/32
    #house base
    @window.draw_quad(
      x, y, lg,
      x+w, y, lg,
      x+w, y+h, lg,
      x, y+h, lg,
      0
    )
    #house roof
    @window.draw_quad(
      x-rd, y, dg,
      x+w+rd, y, dg,
      x+w, y-rd*3/2, dg,
      x, y-rd*3/2, dg,
      0
    )

    #door
    @window.draw_quad(
      x+w-2*rd, y+h, c1,
      x+w-rd, y+h, c1,
      x+w-rd, y+h*1/4, c1,
      x+w-2*rd, y+h*1/4, c1,
      0
    )    

    #window
    @window.draw_quad(
      x+rd, y+h*1/4, b,
      x+2*rd, y+h*1/4, b,
      x+2*rd, y+h/2, b,
      x+rd, y+h/2, b,
      0
    ) 

    draw_octagon(@window, s+l[0]-s/2-s/10,l[1]-s*3/4-s/10, s/5, c)
  end
end