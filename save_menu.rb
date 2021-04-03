class SaveMenu
  def initialize(back_action = nil)
    @board = Res.img(:main_Board)

    text = ConnecMan.player.name == '-' ? '' : ConnecMan.player.name
    @text_field = TextField.new(260, 240, Res.font(:corbel, 32), :main_TextField, :main_TextCursor, nil, 3, 6, 10, true,
                                text, 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789 ') { |t|
      @buttons[:main][0].visible = t != ''
    }
    @buttons = {
      main: [
        Button.new(325, 300, ConnecMan.default_font, ConnecMan.text(:save), :main_btn3, 0xffffff, 0, 0xffff00, 0xff8000) {
          if File.exist?("#{ConnecMan.saves_path}/#{@text_field.text}")
            @state = :confirm
          else
            save_game
          end
        },
        Button.new(325, 340, ConnecMan.default_font, ConnecMan.text(:dont_save), :main_btn3, 0xffffff, 0, 0xffff00, 0xff8000) {
          ConnecMan.show_main_menu
        }
      ],
      confirm: [
        Button.new(325, 300, ConnecMan.default_font, ConnecMan.text(:yes), :main_btn3, 0xffffff, 0, 0xffff00, 0xff8000) {
          save_game
        },
        Button.new(325, 340, ConnecMan.default_font, ConnecMan.text(:no), :main_btn3, 0xffffff, 0, 0xffff00, 0xff8000) {
          @state = :main
        },
      ],
      saved: []
    }
    @buttons[:main][0].visible = @text_field.text != ''
    
    if back_action
      @buttons[:main] << Button.new(325, 400, ConnecMan.default_font, ConnecMan.text(:back), :main_btn3, 0xffffff, 0, 0xffff00, 0xff8000) {
        back_action.call
      }
    end
    
    @state = :main
  end
  
  def save_game
    ConnecMan.save_game(@text_field.text)
    @state = :saved
    @timer = 0
  end
  
  def update
    @buttons[@state].each(&:update)
    
    if @state == :main
      @text_field.update
    elsif @state == :saved
      @timer += 1
      if @timer == 120
        ConnecMan.show_main_menu
      end
    end
  end
  
  def draw
    @board.draw((Const::SCR_W - @board.width) / 2, (Const::SCR_H - @board.height) / 2, 0)
    @buttons[@state].each(&:draw)

    if @state == :main
      ConnecMan.default_font.draw_text_rel(ConnecMan.text(:type_name), Const::SCR_W / 2, 200, 0, 0.5, 0, 1, 1, 0xffffffff)
      @text_field.draw
    elsif @state == :confirm
      ConnecMan.text_helper.write_breaking(ConnecMan.text(:overwrite_confirm).sub('$', @text_field.text), 260, 200, 280, :justified, 0xffffff, 255, 0, 1, 1)
    else
      ConnecMan.default_font.draw_text_rel(ConnecMan.text(:game_saved), Const::SCR_W / 2, Const::SCR_H / 2, 0, 0.5, 0.5, 1, 1, 0xffffff00)
    end
  end
end
