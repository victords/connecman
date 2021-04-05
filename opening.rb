class Opening
  def initialize
    @logo = Res.img(:main_minigl)
    @state = @timer = @alpha = 0
    ConnecMan.play_song(Res.song(:Opening, true, '.mp3'))
  end
  
  def update
    if KB.key_pressed?(Gosu::KB_RETURN) || KB.key_pressed?(Gosu::KB_SPACE) || Mouse.button_pressed?(:left)
      ConnecMan.show_main_menu(false)
    end
    @timer += 1
    if @state == 0 || @state == 2
      @alpha += 5 if @alpha < 255
      if @timer == (@state == 0 ? 240 : 180)
        @state += 1
      end
    elsif @state == 1 || @state == 3
      @alpha -= 5
      if @alpha == 0
        @state += 1
        @timer = 0
        if @state == 4
          ConnecMan.show_main_menu(false)
        end
      end
    end
  end
  
  def draw
    color = (@alpha << 24) | 0xffffff
    if @state <= 1
      y = (Const::SCR_H - @logo.height) / 2
      @logo.draw((Const::SCR_W - @logo.width) / 2, y, 0, 1, 1, color)
      ConnecMan.default_font.draw_text_rel(ConnecMan.text(:powered_by), Const::SCR_W / 2, y - 50, 0, 0.5, 0, 1, 1, color)
    else
      ConnecMan.default_font.draw_text_rel(ConnecMan.text(:presents), Const::SCR_W / 2, Const::SCR_H / 2, 0, 0.5, 0.5, 1, 1, color)
    end
  end
end
