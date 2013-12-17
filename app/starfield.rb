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
  attr_accessor :world_motion, :artifact_array, :radio, :pause_for_story, :story_state, :writer, :last_story_update_time
  attr_reader :ship

  def initialize
    super WINDOW_WIDTH, WINDOW_HEIGHT, false
    self.caption = "Starfield"
    @black = Gosu::Color.new(0xFF000000)
    @star_array = []
    @artifact_array = []
    @ship = Ship.new(self)
    @world_motion = [0.0,0.01];
    @minimap = Minimap.new(self, @ship)
    @writer = Writer.new(self)
    @key_event_handler = KeyEventHandler.new(self)

    @story_state = 0
    @pause_for_story = true
    @last_story_update_time = 0

    setup_writer
    create_stars
    create_artifacts

    @radio = Radio.new(self, @ship, @artifact_array)

  end

  def setup_writer
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
    11.times do
    # 16.times do
      @artifact = Artifact.new(self)
      @artifact_array.push(@artifact)
    end
  end

  def update
    @star_array.each do |star|
      star.update_position(@world_motion)
    end
    
    @key_event_handler.check_keys
    
    update_artifacts_in_range

    @ship.update
    @minimap.update
    @radio.update
    @writer.update
  end

  def update_artifacts_in_range
    @artifact_array.each do |artifact|
      if (artifact.location[0]-@ship.world_position[0]).abs < 1.5*WIDTH && (artifact.location[1]-@ship.world_position[1]).abs < 1.5*HEIGHT
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
    @story_state += 1
    @writer.set_text= STORY[@story_state][0]
    @pause_for_story = STORY[@story_state][1]
  end

  def draw
    self.scale(1.25, 1.25){
      
        #bottom row of stars
      @star_array.each do |s|
        s.draw unless s.z > 1.75
      end

        #flat layer, with artifacts and the ship
      @artifact_array.each do |a|
        a.draw unless !(a.should_draw && a.visible_on_map)
      end

      @ship.draw

        #top layer of stars
      @star_array.each do |s|
        s.draw unless s.z <= 1.75
      end

        #hud
      @minimap.draw
      @writer.draw
      @radio.draw
      
    }
  end
end

window = GameWindow.new
window.show
