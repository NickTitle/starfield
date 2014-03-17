class KeyEventHandler
  def initialize(window)
    @w = window
    @t = Time.now #t flag used for updating the story
    @left = @right = @up = @space = @comma = @period = false
  end

  def check_keys
    @left = @right = @up = @comma = @period = @space = false

    @left = true if @w.button_down? Gosu::KbLeft
    @right = true if @w.button_down? Gosu::KbRight
    @up = true if @w.button_down? Gosu::KbUp
    @space = true if @w.button_down? Gosu::KbSpace
    @comma = true if @w.button_down? Gosu::KbComma
    @period = true if @w.button_down? Gosu::KbPeriod

    case @w.pause_for_story

      when true
        #key bindings for story-critical moments
        window_key_bindings_for_story

        radio_bindings_for_story(@w.radio)
        ship_bindings_for_story(@w.ship)

      when false
        #key bindings for non-story-critical moments
        radio_bindings_non_story(@w.radio)
        ship_bindings_non_story(@w.ship)
    end

    exit if @w.button_down? Gosu::KbEscape

  end

  def window_key_bindings_for_story
    if @w.game_state == 0 && @w.end_screen_transparency > 0
      return
    elsif @w.game_state == 0 && @w.end_screen_transparency == 0 && @space
      @w.game_state = 1
      @w.start_story
    elsif (@w.story_state == 3 && @period)
      @w.update_story
    end
    if !(ARTIFACT_CUES.include?@w.story_state) && @w.story_state != 3 && @space
      @w.update_story
    end
  end

  def radio_bindings_for_story(r) #r = radio object
      return if !([3,4].include?@w.story_state)
      if @period
        r.radio_offset += 0.5 unless r.radio_offset > 274.5
      end
  end

  def radio_bindings_non_story(r)
    if @w.button_down? Gosu::KbComma
        r.radio_offset -= 0.5 unless r.radio_offset < 0.5

        # special case to start ending the game
        if @w.story_state == 60 && r.radio_offset == 0
          @w.update_story
          @w.writer.set_text=""
        end
      end
    if @w.button_down? Gosu::KbPeriod
      r.radio_offset += 0.5 unless r.radio_offset > 274.5
    end
  end

  def ship_bindings_for_story(s) #s = ship

    s.update_world_motion_relative_to_ship

    # turn off artifacts if the conditions are right
    if (ARTIFACT_CUES.include?@w.story_state) && (@w.button_down? Gosu::KbSpace)
      return if Time.now - @w.last_story_update_time < 1
      if s.artifact_to_shut_down != nil
        s.artifact_to_shut_down.found = true
      end
    end


  end

  def ship_bindings_non_story(s) #s = ship

    #figure out whether to move the ship or not
    unless [0,4].include?@w.game_state
      s.update_world_motion_relative_to_ship(@left,@right,@up)
    end

    # if there's an artifact in front of you, and it's not in the story, shut it down!
    if @space && s.artifact_to_shut_down != nil
      s.artifact_to_shut_down.found = true
    end

  end

end
