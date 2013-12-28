class Minimap
  def initialize(window, ship)
    @window = window
    @ship = ship
    @color = ColorPicker.color("map_background")
    @size = 100
    @offset = 10
    @frame_width = 2
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
    w = @frame_width
    b = ColorPicker.color('black')
    f = ColorPicker.color('grill_grey')
    c = @color


    @window.draw_quad(
      o, o, f,
      o+s+2*w, o, f,
      o+s+2*w, o+s+2*w, f,
      o, o+s+2*w, f,
      0
    )

    @window.draw_quad(
      o+w, o+w, b,
      o+s+w, o+w, b,
      o+s+w, o+s+w, b,
      o+w, o+s+w, b,
      0
    )

    # @window.draw_quad(
    #   o, o, c,
    #   o+s, o, c,
    #   o+s, o+s, c,
    #   o, o+s, c,
    #   0
    # )

    if @should_draw_ship
      c = ColorPicker.color("white")
      shipLoc = get_coords_for_position(@ship.location)

      x = o+w+shipLoc[0]
      y = o+w+shipLoc[1]

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
