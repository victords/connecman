class Controller
  def initialize
    @cursor = Res.img(:cursor_Default, true)
    @cursor_points = []
    @cursor_point_index = -1
  end
  
  def reset_current_button
    if @cursor_point_index != -1
      point = @cursor_points[@cursor_point_index]
      point[:button].instance_exec { @state = :up; @img_index = 0 } if point && point[:button]
    end
  end
  
  def set_group(buttons, horizontal = false)
    reset_current_button
    @cursor_points = []
    @cursor_point_index = -1
    buttons.each_with_index do |b, i|
      point = {x: b.x + b.w / 2, y: b.y + b.h / 2, button: b}
      point[horizontal ? :lf : :up] = i > 0 ? i - 1 : buttons.size - 1
      point[horizontal ? :rt : :dn] = i < buttons.size - 1 ? i + 1 : 0
      @cursor_points << point
    end
    set_cursor_point(0)
  end
  
  def set_cursor_point(index)
    reset_current_button
    @cursor_point_index = index
    new_point = @cursor_points[index]
    new_point[:button].instance_exec { @state = :over; @img_index = 1 } if new_point && new_point[:button]
  end
  
  def update
    return if ConnecMan.mouse_control

    point = @cursor_points[@cursor_point_index]
    return unless point
    
    if KB.key_pressed?(Gosu::KB_SPACE) || KB.key_pressed?(Gosu::KB_RETURN)
      point[:button].click
    elsif point[:up] && (KB.key_pressed?(Gosu::KB_UP) || KB.key_held?(Gosu::KB_UP))
      set_cursor_point(point[:up])
    elsif point[:rt] && (KB.key_pressed?(Gosu::KB_RIGHT) || KB.key_held?(Gosu::KB_RIGHT))
      set_cursor_point(point[:rt])
    elsif point[:dn] && (KB.key_pressed?(Gosu::KB_DOWN) || KB.key_held?(Gosu::KB_DOWN))
      set_cursor_point(point[:dn])
    elsif point[:lf] && (KB.key_pressed?(Gosu::KB_LEFT) || KB.key_held?(Gosu::KB_LEFT))
      set_cursor_point(point[:lf])
    end
  end
  
  def draw
    if ConnecMan.mouse_control
      @cursor.draw(Mouse.x - @cursor.width / 2, Mouse.y, 0)
    else
      point = @cursor_points[@cursor_point_index]
      @cursor.draw(point[:x] - @cursor.width / 2, point[:y], 0) if point
    end
  end
end
