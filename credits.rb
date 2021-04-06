class Credits < Controller
  def initialize
    super
    @bg = Res.img(:main_BackgroundFinish, false, false, '.jpg')
    @text_helper = TextHelper.new(ConnecMan.image_font, 5)
    @save_menu = SaveMenu.new
    @timer = 0
    
    ConnecMan.play_song(Res.song(:Closing, false, '.mp3'))
  end
  
  def set_cursor_points
    reset_current_button
    @cursor_points = @save_menu.get_cursor_points
    @cursor_point_index = -1
    set_cursor_point(0)
  end
  
  def update
    super
    set_cursor_points if @timer == 599 || @timer == 600 && @save_menu.points_refreshed
    
    @timer += 1 if @timer < 600
    if @timer == 600
      @save_menu.update
      set_cursor_points if @save_menu.points_refreshed
    end
  end
  
  def draw
    @bg.draw(0, 0, 0)
    
    @text_helper.write_breaking(ConnecMan.text(:finish_message), 10, 485, 780, :left, 0xffffff, 255, 0, 0.9, 0.9)
    @text_helper.write_breaking(ConnecMan.text(:finish_message2), 10, 575, 780, :left, 0xffffff, 255, 0, 0.5, 0.5)
    
    @save_menu.draw if @timer == 600
    
    super
  end
end
