class KeyEventHandler
  def initialize(window)
    @w = window
    @t = Time.now #t flag used for updating the story
  end

  def check_keys
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
    if (@w.story_state == 3 && (@w.button_down? Gosu::KbPeriod))
      @w.update_story
    end
    if !([3,11].include?@w.story_state) && (@w.button_down? Gosu::KbSpace)
      @w.update_story
    end
  end

  def radio_bindings_for_story(r) #r = radio object
      return if !([3,4].include?@w.story_state)
      if @w.button_down? Gosu::KbPeriod
        r.radio_offset += 0.5 unless r.radio_offset > 274.5
      end
  end

  def radio_bindings_non_story(r)
    if @w.button_down? Gosu::KbComma
        r.radio_offset -= 0.5 unless r.radio_offset < 0.5
      end
    if @w.button_down? Gosu::KbPeriod
      r.radio_offset += 0.5 unless r.radio_offset > 274.5
    end
  end

  def ship_bindings_for_story(s) #s = ship
    
    s.update_world_motion_relative_to_ship
    
    # turn off artifacts if the conditions are right
    if ([11,16].include?@w.story_state) && (@w.button_down? Gosu::KbSpace)
      return if Time.now - @w.last_story_update_time < 1
      if s.artifact_to_shut_down != nil
        s.artifact_to_shut_down.found = true
      end
    end


  end

  def ship_bindings_non_story(s) #s = ship

    #figure out whether to move the ship or not
    left = right = up = space = false

    left = true if @w.button_down? Gosu::KbLeft
    right = true if @w.button_down? Gosu::KbRight
    up = true if @w.button_down? Gosu::KbUp
    space = true if @w.button_down? Gosu::KbSpace

    s.update_world_motion_relative_to_ship(left,right,up)

    #clear the writer if you start piloting the ship at the end of a story time
    if ([7,14].include?@w.story_state) && @w.writer.text.length > 0 && (left || right || up)
      @w.writer.set_text=""
      @w.last_story_update_time = Time.now
    end
    
    # if there's an artifact in front of you, and it's not in the story, shut it down!
    if space && s.artifact_to_shut_down != nil
      s.artifact_to_shut_down.found = true
    end

  end

end