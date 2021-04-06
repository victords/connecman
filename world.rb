require_relative 'save_menu'

include MiniGL

class World < Controller
  WHITE = 0xffffffff
  
  def initialize(num)
    super()

    @buttons = [
      Button.new(640, 480, nil, nil, :main_btn1) {
        ConnecMan.load_stage(@num, @cur_spot)
      },
      Button.new(640, 520, nil, nil, :main_btn1) {
        ConnecMan.show_status
      },
      Button.new(640, 560, nil, nil, :main_btn1) {
        if ConnecMan.player.scores.empty?
          ConnecMan.show_main_menu
        else
          set_save_cursor_points
          @state = :save
        end
      }
    ]
    set_world(num)

    @water = Res.img(:map_water, true, true)
    @water_timer = 0
    @alpha = 255
    @save_menu = SaveMenu.new(Proc.new {
      @state = :main
      set_cursor_points
    })
    
    @state = :main
  end

  def set_world(num)
    @num = num
    @bg = Res.img("map_Map#{@num}")

    @last_spot = @cur_spot = ConnecMan.player.last_world > num ? 5 : (ConnecMan.player.last_stage - 1) % 6

    spots = case @num
            when 1 then [[200, 370], [282, 490], [515, 407], [340, 380], [477, 319], [515, 232]]
            when 2 then [[418, 542], [321, 495], [279, 377], [439, 308], [730, 415], [295, 118]]
            when 3 then [[367, 97], [220, 207], [212, 348], [267, 478], [639, 386], [472, 334]]
            when 4 then [[206, 327], [220, 447], [454, 521], [616, 403], [604, 277], [405, 266]]
            else        [[347, 329]]
            end
    @spots = spots.map { |s| Vector.new(s[0], s[1]) }
    @spot_buttons = []
    @spots.each_with_index do |s, i|
      @spot_buttons << Button.new(s.x - 16, s.y - 12, nil, nil, :map_Spot) {
        @cur_spot = i
      }
    end
    @man = GameObject.new(@spots[@cur_spot].x, @spots[@cur_spot].y, 0, 0, :map_man, Vector.new(-16, -54), 5, 1)
    
    set_arrow_buttons
    set_cursor_points
    
    ConnecMan.play_song(Res.song("world#{@num}", false, '.mp3'))
  end

  def set_arrow_buttons
    @arrow_buttons = []
    if @num < ConnecMan.player.last_world
      @arrow_buttons << Button.new(10, 10, nil, nil, :main_btnUp) do
        @transition = @num + 1
        @timer = 0
      end
    end
    if @num > 1
      @arrow_buttons << Button.new(10, 26, nil, nil, :main_btnDown) do
        @transition = @num - 1
        @timer = 0
      end
    end
  end
  
  def set_cursor_points
    set_group(@buttons + @arrow_buttons + @spot_buttons[0..@last_spot])
  end
  
  def set_save_cursor_points
    reset_current_button
    @cursor_points = @save_menu.get_cursor_points
    @cursor_point_index = -1
    set_cursor_point(0)
  end
  
  def resume
    ConnecMan.play_song(Res.song("world#{@num}", false, '.mp3'))
    set_cursor_points
  end
  
  def advance_level
    @cur_spot += 1
    @last_spot += 1
    @man.x = @spots[@cur_spot].x
    @man.y = @spots[@cur_spot].y
  end

  def update
    super
    set_save_cursor_points if @state == :save && @save_menu.points_refreshed
    
    if @transition
      @timer += 1
      if @timer < 20
        @alpha = (255 * (1 - @timer.to_f / 20)).floor
      elsif @timer < 40
        @alpha = (255 * ((@timer - 20).to_f / 20)).floor
        set_world(@transition) if @timer == 20
      else
        @alpha = 255
        @transition = nil
      end
    else
      if @state == :save
        @save_menu.update
        set_save_cursor_points if @save_menu.points_refreshed
      elsif ConnecMan.mouse_control
        @buttons.each(&:update)
        @spot_buttons.each_with_index do |s, i|
          s.update if i != @cur_spot && i <= @last_spot
        end
        @arrow_buttons.each(&:update)
      end
      
      @man.animate([0, 1, 2, 1, 0, 3, 4, 3], 8)
      if @man.x != @spots[@cur_spot].x || @man.y != @spots[@cur_spot].y
        ConnecMan.play_sound('3') if @man.speed.x == 0 && @man.speed.y == 0
        @man.move_free(@spots[@cur_spot], 4)
      end
    end

    @water_timer += 1
    @water_timer = 0 if @water_timer == 40
  end
  
  def draw
    offset = @water_timer < 20 ? 0 : 10
    (0..4).each do |i|
      (0..2).each do |j|
        @water.draw((i - 1) * 200 + offset, j * 201, 0)
      end
    end

    color = (@alpha << 24) | 0xffffff
    @bg.draw(0, 0, 0, 1, 1, color)

    @spot_buttons.each_with_index do |b, i|
      b.draw(@alpha) if i <= @last_spot
    end
    @arrow_buttons.each do |b|
      b.draw(@alpha)
    end
    @buttons.each_with_index do |b, i|
      b.draw
      text = ConnecMan.text(i == 0 ? :play : i == 1 ? :status : :exit).upcase
      ConnecMan.image_font.draw_text_rel(text, b.x + b.w / 2, b.y + b.h / 2, 0, 0.5, 0.5, 0.6, 0.6, 0xff000000)
    end

    @spots.each_with_index do |s, i|
      ConnecMan.image_font.draw_text_rel((i + 1).to_s, s.x, s.y - 10, 0, 0.5, 0, 0.3, 0.3, @alpha << 24) if i <= @last_spot
    end
    @man.draw(nil, 1, 1, @alpha)
    score = ConnecMan.player.scores[(@num - 1) * 6 + @cur_spot]
    if score && @man.x == @spots[@cur_spot].x && @man.y == @spots[@cur_spot].y
      ConnecMan.image_font.draw_text_rel(ConnecMan.text(:score) + score.to_s, @spots[@cur_spot].x, @spots[@cur_spot].y + 8, 0, 0.5, 0, 0.3, 0.3, @alpha << 24)
    end

    ConnecMan.image_font.draw_text(ConnecMan.text("world_#{@num}").upcase, 50, 10, 0, 0.8, 0.8, color)
    ConnecMan.image_font.draw_text(ConnecMan.text(:player) + ConnecMan.player.name.upcase, 10, 540, 0, 0.5, 0.5, WHITE)
    ConnecMan.image_font.draw_text(ConnecMan.text(:score) + ConnecMan.player.scores.sum.to_s, 10, 570, 0, 0.5, 0.5, WHITE)
    
    @save_menu.draw if @state == :save
    
    super
  end
end
