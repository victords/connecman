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
      if horizontal
        point[:lf] = i - 1 if i > 0
        point[:rt] = i + 1 if i < buttons.size - 1
      else
        point[:up] = i - 1 if i > 0
        point[:dn] = i + 1 if i < buttons.size - 1
      end
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
    
    if KB.key_pressed?(Gosu::KB_SPACE)
      point[:button].click
    elsif KB.key_pressed?(Gosu::KB_UP) && point[:up]
      set_cursor_point(point[:up])
    elsif KB.key_pressed?(Gosu::KB_RIGHT) && point[:rt]
      set_cursor_point(point[:rt])
    elsif KB.key_pressed?(Gosu::KB_DOWN) && point[:dn]
      set_cursor_point(point[:dn])
    elsif KB.key_pressed?(Gosu::KB_LEFT) && point[:lf]
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
