class Radio
  attr_accessor :radio_offset
  def initialize(window, ship, artifacts)

    @window = window
    @ship = ship
    @artifact_array = artifacts
    @radio_offset = 0

    static_sound_object = Gosu::Sample.new(window, "media/sfx/static.mp3")
    @static = static_sound_object.play(0,1,true)

    power_button_sound_object = Gosu::Sample.new(window, "media/sfx/button.mp3")
    @power_button = power_button_sound_object

    @reception_color = ColorPicker.color('white')
    @black = ColorPicker.color('black')
    @radio_grey = ColorPicker.color('radio_grey')
    @white = ColorPicker.color('white')

    @broadcast_range = 8
    @state = "off"

  end

  def update

    if @radio_offset == 0
      @static.volume = 0
      @ship.show_sonar = false
      # turn off artifacts
      @artifact_array.each do |a|
        a.broadcast.volume = 0
        a.visible_on_map = false
      end
      @ship.artifact_to_shut_down = nil
      # play the power button off sound if it just turned off
      if @state .== "on"
        @power_button.play(1,1,false)
        @state = "off"
      end

      return
    else

      artifacts_to_update = find_artifacts_in_broadcast_range

      if artifacts_to_update.length > 0
        @ship.show_sonar = true
        react_to_artifacts(artifacts_to_update)
      else
        @static.volume = 0.75
        @ship.show_sonar = false
      end

      if @state == "off"
        @power_button.play(1,1,false)
        @state = "on"
      end
    end
  end

  def find_artifacts_in_broadcast_range
    broadcasting_artifacts = []

    @artifact_array.each do |a|
      signal_closeness = (@radio_offset-a.frequency).abs
      signal_strength = @broadcast_range - signal_closeness
      if signal_closeness < @broadcast_range &&  broadcasting_artifacts.length < 2 && !a.turned_off
        broadcasting_artifacts.push([a,distance(@ship.location, a.location), signal_strength])
      else
        a.broadcast.volume = 0
        a.visible_on_map = false
      end
    end

    #sort by signal strength
    broadcasting_artifacts.sort_by! { |x| x[2]}
  end

  def react_to_artifacts(artifacts)
    @ship.artifact_to_shut_down = nil unless @window.pause_for_story
      artifacts.each do |a|
        # artifact in question
        aIQ = a[0]

        signal_component = (0.6-0.6*((@broadcast_range-a[2])/(@broadcast_range)))
        distance_component = (0.45-0.45*(a[1]/(WORLD_SIZE)))
        broadcast_volume = (signal_component + distance_component)
        broadcast_volume = 1 if broadcast_volume > 1

        # let closest artifact set volumes, control sonar, etc
        if a == artifacts.first


          ## STORY CODE

          ## END STORY CODE

          scaled_volume = (255*broadcast_volume).round

          if @window.story_state == 4 && broadcast_volume > 0.5
            @window.update_story

          end
          @reception_color = ColorPicker.color('full_reception', scaled_volume)
          aIQ.visible_on_map = true
          aIQ.broadcast.volume = broadcast_volume
          aIQ.broadcast.volume = 0 if aIQ.found
          # a[1] is distance between ship and object
          # if it's less than half a screen, put the ship in orbit
          if a[1] < HEIGHT/2 && a[1] < WIDTH/2
            react_to_close_artifact(aIQ)
          else

            @static.volume = (1-broadcast_volume) * 0.75
            @ship.artifact_to_shut_down = nil unless @window.pause_for_story
          end

          @ship.sonar_array.each do |s|
            s.next_angle = get_angle(aIQ.location, @ship.location)
            @ship.countdown_max = 180 * 1-broadcast_volume + 20
          end
          7
        else
          # set radio volume for other elements, scaled by index in array
          aIQ.broadcast.volume = broadcast_volume * 0.2**artifacts.index(a)
          aIQ.visible_on_map = false
        end
      end
  end

  def react_to_close_artifact(aIQ)
    @static.volume = 0
    @ship.artifact_to_shut_down = aIQ

    ### STORY CODE
    # find out if you're supposed to advance the story upon reaching this artifact
    if RADIO_CUES.include?@window.story_state
      @window.update_story unless DEBUG
      @ship.play_engine_sound('off')
    end
    # if @window.pause_for_story
    #   wM = @window.world_motion
    #   wM[0] *= 0.95
    #   wM[1] *= 0.95
    # end
    ### END STORY CODE
  end

  def draw
    draw_behind_grill
    draw_grill
    draw_frame
    draw_dial_base
    draw_tune_lines
    draw_tuner
    draw_knobs
  end

  def draw_behind_grill
    bg = ColorPicker.color('white')
    c = @reception_color
    @window.draw_quad(
      11, HEIGHT-68, bg,
      139, HEIGHT-68, bg,
      139, HEIGHT, bg,
      11, HEIGHT, bg,
      0
    )
    @window.draw_quad(
      11, HEIGHT-68, bg,
      17, HEIGHT-73, bg,
      132, HEIGHT-73, bg,
      139, HEIGHT-68, bg,
      0
    )
  end

  def draw_grill
    t = 3  #thickness
    x = 19
    y = HEIGHT-65

    c1 = ColorPicker.color("radio_grey")
    c2 = ColorPicker.color("dark_grey")
    20.times do |i|
      12.times do |j|
       c = c1
       if i.between?(2,8) && j.between?(2,8)
          c = c2
        end
        @window.draw_quad(
          x+(t*2*i-t/2), y+(t*2*j-t/2), c,
          x+(t*2*i-t/2), y+(t*2*j+t/2), c,
          x+(t*2*i+t/2), y+(t*2*j+t/2), c,
          x+(t*2*i+t/2), y+(t*2*j-t/2), c,
          0
        )
      end
    end
  end

  def draw_frame
    t = 4
    h = 75
    w = 130
    x = 10
    y = HEIGHT - h
    c = ColorPicker.color('frame_blue')

      #left blue
    @window.draw_quad(
        x, y+2*t, c,
        x+t, y+2*t, c,
        x+t, y+h, c,
        x, y+h, c,
        0
      )

    #left angle
    @window.draw_quad(
        x, y+2*t, c,
        x+2*t, y, c,
        x+2*t, y+t, c,
        x+t, y+2*t, c,
        0
      )

      #top blue
    @window.draw_quad(
        x+2*t, y, c,
        x+2*t+(w-4*t), y, c,
        x+2*t+(w-4*t), y+t, c,
        x+2*t, y+t, c,
        0
      )

      #left angle
    @window.draw_quad(
        x+2*t+(w-4*t), y, c,
        x+w, y+2*t, c,
        x+w-t, y+2*t, c,
        x+2*t+(w-4*t), y+t, c,
        0
      )

      #right blue
    @window.draw_quad(
        x+w-t, y+2*t, c,
        x+w, y+2*t, c,
        x+w, y+h, c,
        x+w-t, y+h, c,
        0
      )
  end

  def draw_dial_base
    c = ColorPicker.color('dark_grey')
    c1 = ColorPicker.color('white')
    b = ColorPicker.color('black')

    x = 85
    y = HEIGHT - 60
    size = 40

    draw_octagon(@window, x, y, size, c)

    draw_octagon(@window, x+2, y+2, size-4, c1)
    if @radio_offset > 0
      on_off_color = @reception_color
    else
      on_off_color = ColorPicker.color('radio_grey')
    end
    draw_octagon(@window, x+2, y+2, size-4, on_off_color)
  end

  def draw_tune_lines
    c = ColorPicker.color('dark_grey')
    x = 85
    y = HEIGHT - 60
    size = 40

    #1 (line)
    @window.draw_quad(
      x+5, y+size/2-2, c,
      x+10, y+size/2-2, c,
      x+10, y+size/2-1, c,
      x+5, y+size/2-1, c,
      0
    )

    #2
    @window.draw_quad(
      x+7, y+size/2-7, c,
      x+8, y+size/2-7, c,
      x+8, y+size/2-6, c,
      x+7, y+size/2-6, c,
      0
    )

    #3 (star)
    @window.draw_quad(
      x+size/4, y+size/4-1, c,
      x+size/4+1, y+size/4-2, c,
      x+size/4+2, y+size/4-1, c,
      x+size/4+1, y+size/4, c,
      0
    )

    #4
    @window.draw_quad(
      x+15, y+size/2-13, c,
      x+16, y+size/2-13, c,
      x+16, y+size/2-12, c,
      x+15, y+size/2-12, c,
      0
    )

    #5 (line)
    @window.draw_quad(
      x+size/2, y+4, c,
      x+size/2, y+10, c,
      x+size/2+1, y+10, c,
      x+size/2+1, y+4, c,
      0
    )

    #6
    @window.draw_quad(
      x+size-15, y+size/2-13, c,
      x+size-16, y+size/2-13, c,
      x+size-16, y+size/2-12, c,
      x+size-15, y+size/2-12, c,
      0
    )

    #7 (star)
    @window.draw_quad(
      x+size-(size/4), y+size/4-1, c,
      x+size-(size/4+1), y+size/4-2, c,
      x+size-(size/4+2), y+size/4-1, c,
      x+size-(size/4+1), y+size/4, c,
      0
    )

    #8
    @window.draw_quad(
      x+size-7, y+size/2-7, c,
      x+size-8, y+size/2-7, c,
      x+size-8, y+size/2-6, c,
      x+size-7, y+size/2-6, c,
      0
    )

    #9 (line)
    @window.draw_quad(
      x+size-5, y+size/2-2, c,
      x+size-10, y+size/2-2, c,
      x+size-10, y+size/2-1, c,
      x+size-5, y+size/2-1, c,
      0
    )

  end

  def draw_tuner
    x = 99
    y = HEIGHT-47
    s = 12.0
    white = ColorPicker.color("white")
    dark_grey = ColorPicker.color("dark_grey")
    dial = ColorPicker.color("dial_orange")
    @window.rotate((@radio_offset/275.0 * 180), x+s/2, y+s/2){
      draw_octagon(@window,x-1,y-1,s+2, dark_grey)
      draw_octagon(@window,x,y,s, white)
      draw_octagon(@window,x-8,y+4, s/4, dial)
    }
    @window.draw_quad(
      x+2, y+17, dark_grey,
      x+11, y+17, dark_grey,
      x+11, y+18, dark_grey,
      x+2, y+18, dark_grey,
      0
    )
    @window.draw_quad(
      x+5, y+17, dial,
      x+8, y+17, dial,
      x+8, y+16, dial,
      x+5, y+16, dial,
      0
    )
  end

  def draw_knobs
    x = 94
    y = HEIGHT - 15
    s = 8
    black = ColorPicker.color('dark_grey')
    white = ColorPicker.color('white')
    dial = ColorPicker.color('dial_orange')
    left_knob_rotate = (@radio_offset > 0) ? 45 : 0
    @window.rotate(left_knob_rotate, x+s/2, y+s/2){
      draw_octagon(@window,x-1,y-1,s+2, black)
      draw_octagon(@window,x,y,s, white)
      draw_octagon(@window,x+1,y, 2, dial)
    }
    x = 109
    @window.rotate(720*@radio_offset/275, x+s/2, y+s/2){
      draw_octagon(@window,x-1,y-1,s+2, black)
      draw_octagon(@window,x,y,s, white)
      draw_octagon(@window,x-1, y+3, 2, dial)
    }
  end
end
