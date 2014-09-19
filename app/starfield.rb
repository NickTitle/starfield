#!/usr/bin/env ruby
require 'gosu'

require './classes/ship.rb'
require './classes/radio.rb'
require './classes/artifact.rb'
require './classes/star.rb'
require './classes/particle.rb'
require './classes/sonar_bar.rb'

require './classes/minimap.rb'
require './classes/writer.rb'

require './key_event_handler.rb'
require './helpers.rb'
require './constants.rb'

class GameWindow < Gosu::Window
  attr_accessor :world_motion, :artifact_array, :radio, :pause_for_story, :story_state, :writer, :last_story_update_time, :game_state
  attr_reader :ship, :end_screen_transparency

  def initialize
    super WINDOW_WIDTH, WINDOW_HEIGHT, false
    self.caption = "Starfield"

    #game states
    #0= intro
    #1= gameplay
    #2= fadeout
    #3= pause after fadeout
    #4= fadein
    
    @game_state = 0

    @black = Gosu::Color.new(0xFF000000)
    @star_array = []
    @artifact_array = []
    @ship = Ship.new(self)
    @world_motion = [0.0,0.01];
    @minimap = Minimap.new(self, @ship)
    @writer = Writer.new(self)
    @key_event_handler = KeyEventHandler.new(self)
    @last_story_update_time = Time.now
    @fade_back_in_timer == 0
    @clock_time_to_fade_back_in = Time.now
    @clock_time_to_go_black = Time.now
    @story_ending = false
    @end_screen_transparency = 255
    @scale = WINDOW_WIDTH/(WIDTH*1.000)
    @space_blue = ColorPicker.color('space')


    if !DEBUG
      @story_state = 0
      @pause_for_story = true
    else
      @game_state = 1
      @story_state = 99999
      @pause_for_story = false
    end

    ## custom debug flags
    # @story_state = 58
    # @pause_for_story = true
    # @game_state = 4
    # @end_screen_transparency = 0

    create_stars
    create_artifacts

    @radio = Radio.new(self, @ship, @artifact_array)

  end

  def start_story
    @writer.set_text=(STORY[@story_state][0])
    @pause_for_story = true
    @last_story_update_time = Time.now
  end

  #create a set of stars for your ship to fly through
  def create_stars
    150.times do
      @star = Star.new(self)
      @star_array.push(@star)
    end
  end

  def create_artifacts
    artifact_count = DEBUG ? 1 : 11
    artifact_count.times do
      @artifact = Artifact.new(self)
      @artifact_array.push(@artifact)
    end
  end

  def update

    @key_event_handler.check_keys

    @star_array.each do |star|
      star.update_position(@world_motion)
    end

    update_artifacts_in_range

    @ship.update
    @minimap.update
    @radio.update
    @writer.update

    update_for_game_state_change

  end

  def update_artifacts_in_range
    @artifact_array.each do |artifact|
      if (artifact.location[0]-@ship.location[0]).abs < 1.5*WIDTH && (artifact.location[1]-@ship.location[1]).abs < 1.5*HEIGHT
        artifact.update
        artifact.should_draw = true
      else
        artifact.should_draw = false
      end
    end
  end

  def update_story
    return if Time.now - @last_story_update_time < 1
    @last_story_update_time = Time.now

    if @story_state == STORY.length - 1
      @game_state = 2
      # @pause_for_story = true
      return
    end

    @story_state += 1
    @writer.set_text= STORY[@story_state][0]
    @pause_for_story = STORY[@story_state][1]
  end

  def update_for_game_state_change
    if @game_state == 0 && @end_screen_transparency > 0
      @end_screen_transparency -= 1 #0.5
    elsif @game_state == 2 && @end_screen_transparency < 255
      @end_screen_transparency += 0.5
    elsif @game_state == 2 && @end_screen_transparency >= 255
      @pause_for_story = true
      @game_state = 3
      @clock_time_to_fade_back_in = Time.now+25
      @clock_time_to_go_black = Time.now+73
      @fade_back_in_timer = 240
      end_sound = Gosu::Sample.new(self, "media/songs/game_end.mp3")
      end_sound.play(1,1,false)
    end

    update_finale unless(is_gameplay_state? || @game_state == 0)
  end

  def update_finale
    if @game_state == 3 && (@clock_time_to_fade_back_in > Time.now)
      return
    elsif @game_state == 3 && (@clock_time_to_fade_back_in <= Time.now)
      @game_state = 4
    elsif @game_state == 4 && @end_screen_transparency > 0
      @end_screen_transparency -= 0.3
    elsif @clock_time_to_go_black < Time.now && game_state == 4
      @game_state = 5
      @end_screen_transparency = 255
    end
  end

  def draw
    self.scale(@scale, @scale){

      s = @space_blue
      self.draw_quad(
        0, 0, s,
        WIDTH, 0, s,
        WIDTH, HEIGHT, s,
        0, HEIGHT, s,
        0
      )

      draw_for_gameplay
      @writer.draw_title if @game_state == 0
      draw_fade_out if ([0,2,3,4,5].include?@game_state)
    }
  end

  def draw_for_gameplay
    #bottom row of stars
    @star_array.each do |s|
      s.draw unless s.z > 1.75
    end

      #flat layer, with artifacts and the ship
    if is_gameplay_state?
      @artifact_array.each do |a|
        a.draw if distance(a.location, @ship.location)<1.5*WIDTH#unless !(a.should_draw && a.visible_on_map)
      end
    end

    @ship.draw

      #top layer of stars
    @star_array.each do |s|
      s.draw unless s.z <= 1.75
    end

      #hud
      if is_gameplay_state?
        @minimap.draw
        @writer.draw
        @radio.draw
      end
  end

  def draw_fade_out
    c = ColorPicker.color('fade_out', @end_screen_transparency.round)
      self.draw_quad(
        0, 0, c,
        WIDTH, 0, c,
        WIDTH, HEIGHT, c,
        0, HEIGHT, c,
        0
      )
  end

  def is_gameplay_state?
    return ([1,2].include?@game_state)
  end

end

window = GameWindow.new
window.show
