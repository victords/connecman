class Credits
  def initialize
    @bg = Res.img(:main_BackgroundFinish, false, false, '.jpg')
    @text_helper = TextHelper.new(ConnecMan.image_font, 5)
    @save_menu = SaveMenu.new
    @timer = 0
    
    ConnecMan.play_song(Res.song(:Closing, false, '.mp3'))
  end
  
  def update
    @timer += 1 if @timer < 600
    if @timer == 600
      @save_menu.update
    end
  end
  
  def draw
    @bg.draw(0, 0, 0)
    
    @text_helper.write_breaking(ConnecMan.text(:finish_message), 10, 485, 780, :left, 0xffffff, 255, 0, 0.9, 0.9)
    @text_helper.write_breaking(ConnecMan.text(:finish_message2), 10, 575, 780, :left, 0xffffff, 255, 0, 0.5, 0.5)
    
    @save_menu.draw if @timer == 600
  end
end
