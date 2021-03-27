class StatusScreen
  BLACK = 0xff000000
  
  def initialize
    @font = ConnecMan.default_font
    @bg = Res.img(:main_BackgroundStatus, false, true)
    @man = Res.imgs(:map_man, 5, 1)[0]

    @world = ConnecMan.player.last_world
    @level = ConnecMan.player.last_stage
    @stage_num = (@level - 1) % 6 + 1
    @cur_world = @world
    
    @thumbnails = (0...@world).map { |i| Res.img("main_MapThumbnail#{i}", false, false, '.jpg') }
    @crystals = (0...(@world-1)).map { |i| Res.img("main_crystal#{i}") }
    @shadow = Res.img(:main_CursorHighlight)
    
    @piece = Res.imgs(:board_pieces, 5, 2)[9]
    @symbols = Res.imgs(:symbols_white, 8, 4)
    
    @ok_button = Button.new(325, 553, nil, nil, :main_btn1) {
      ConnecMan.resume_world
    }
    set_arrow_buttons
  end
  
  def set_arrow_buttons
    @arrow_buttons = []
    if @cur_world < @world
      @arrow_buttons << Button.new(384, 317, nil, nil, :main_btnUp) {
        @cur_world += 1
        set_arrow_buttons
      }
    end
    if @cur_world > 1
      @arrow_buttons << Button.new(384, 333, nil, nil, :main_btnDown) {
        @cur_world -= 1
        set_arrow_buttons
      }
    end
  end
  
  def update
    @ok_button.update
    @arrow_buttons.each(&:update)
  end
  
  def draw
    (0..3).each do |i|
      (0..2).each do |j|
        @bg.draw(i * @bg.width, j * @bg.height, 0)
      end
    end
    
    @font.draw_text_rel(ConnecMan.text(:status), Const::SCR_W / 2, 10, 0, 0.5, 0, 1, 1, BLACK)
    
    @man.draw(40, 50, 0)
    @font.draw_text(ConnecMan.player.name, 80, 54, 0, 1, 1, BLACK)
    @font.draw_text(ConnecMan.text(:level) + @level.to_s + " (#{ConnecMan.text("world_#{@world}")} - #{@stage_num})", 80, 84, 0, 1, 1, BLACK)
    
    @font.draw_text_rel(ConnecMan.text(:worlds_unlocked), 250, 130, 0, 0.5, 0, 1, 1, BLACK)
    @thumbnails[@cur_world - 1].draw(50, 160, 0)
    @font.draw_text_rel("#{@cur_world} - #{ConnecMan.text("world_#{@cur_world}")}", 210, 324, 0, 0.5, 0, 1, 1, BLACK)

    @font.draw_text_rel(ConnecMan.text(:crystals_collected), 650, 130, 0, 0.5, 0, 1, 1, BLACK)
    (0..3).each do |i|
      if i < @world - 1
        @crystals[i].draw(576 + (i % 2) * 84, 160 + (i / 2) * 100, 0)
        @font.draw_text_rel(ConnecMan.text("crystal_#{i}"), 608 + (i % 2) * 84, 225 + (i / 2) * 100, 0, 0.5, 0, 1, 1, BLACK)
      else
        @shadow.draw(576 + (i % 2) * 84, 160 + (i / 2) * 100, 0, 2, 2, BLACK)
      end
    end

    @font.draw_text_rel(ConnecMan.text(:nisled_alphabet), Const::SCR_W / 2, 375, 0, 0.5, 0, 1, 1, BLACK)
    ConnecMan::SYMBOL_NAMES.each_with_index do |s, i|
      x = 45 + (i % 11) * 65
      y = 415 + (i / 11) * 45
      if ConnecMan.player.learned_symbols[i]
        @piece.draw(x, y, 0)
        @symbols[i].draw(x, y, 0)
        @font.draw_text(s[0], x + 35, y + 4, 0, 0.6, 0.6, BLACK)
        @font.draw_text(s[1], x + 35, y + 20, 0, 0.6, 0.6, BLACK)
      else
        @shadow.draw(x, y, 0, 1, 1, BLACK)
      end
    end
    
    @ok_button.draw
    @arrow_buttons.each(&:draw)
    
    ConnecMan.image_font.draw_text_rel(ConnecMan.text(:ok), @ok_button.x + @ok_button.w / 2, @ok_button.y + @ok_button.h / 2, 0, 0.5, 0.5, 0.6, 0.6, BLACK)
  end
end
