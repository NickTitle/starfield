class Minimap
  def initialize(window, ship)
    @window = window
    @ship = ship
    @color = ColorPicker.color("map_background")
    @size = 100
    @offset = 10
    @cycle_count = 0
    @should_draw_ship = true
  end

  def update
    if @cycle_count >= 60
      @should_draw_ship = !@should_draw_ship 
      @cycle_count = 0
    else
      @cycle_count += 1
    end
  end

  def draw
    o = @offset
    s = @size
    c = @color

    @window.draw_quad(
      o, o, c,
      o+s, o, c,
      o+s, o+s, c,
      o, o+s, c,
      0
    )

    if @should_draw_ship
      c = ColorPicker.color("white")
      shipLoc = get_coords_for_position(@ship.world_position)
      
      x = o+shipLoc[0]
      y = o+shipLoc[1]

      @window.draw_quad(
        x, y, c,
        x, y+3, c,
        x+3, y+3, c,
        x+3, y, c,
        0
      )
    end

    @window.artifact_array.each do |a|
      if a.visible_on_map
        c = a.color
        loc = get_coords_for_position(a.location)
        x = o+loc[0]
        y = o+loc[1]

        @window.draw_quad(
          x, y, c,
          x, y+3, c,
          x+3, y+3, c,
          x+3, y, c,
          0
        )
      end
    end
  end

  def get_coords_for_position(position)
    x = position[0]/WORLD_SIZE * @size
    y = position[1]/WORLD_SIZE * @size
    return [x.round(2),y.round(2)]
  end
end