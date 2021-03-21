require_relative 'global'

class Menu
  def initialize
    @bg_start = Res.img(:main_BackgroundStart, true, false, '.jpg')
    @bgm_start = Res.song(:Opening, true, '.mp3')

    @controls = {
      main: [
        Button.new(90, 225, ConnecMan.default_font, ConnecMan.text(:play), :main_btn2, 0x333300, 0, 0x666633, 0x333300, false, true, 8) {
          set_state :play
        },
        Button.new(90, 265, ConnecMan.default_font, ConnecMan.text(:instructions), :main_btn2, 0x333300, 0, 0x666633, 0x333300, false, true, 8) {
          set_state :instructions
        },
        Button.new(90, 305, ConnecMan.default_font, ConnecMan.text(:options), :main_btn2, 0x333300, 0, 0x666633, 0x333300, false, true, 8) {
          set_state :options
        },
        Button.new(90, 345, ConnecMan.default_font, ConnecMan.text(:more), :main_btn2, 0x333300, 0, 0x666633, 0x333300, false, true, 8) {
          set_state :more
        },
        Button.new(90, 405, ConnecMan.default_font, ConnecMan.text(:exit), :main_btn2, 0x333300, 0, 0x666633, 0x333300, false, true, 8) {
          exit(0)
        }
      ],
      play: [
        Button.new(325, 240, ConnecMan.default_font, ConnecMan.text(:new_game), :main_btn3, 0xffffff, 0, 0xffff00, 0xff8000) {
          ConnecMan.new_game
        },
        Button.new(325, 300, ConnecMan.default_font, ConnecMan.text(:continue), :main_btn3, 0xffffff, 0, 0xffff00, 0xff8000) {
          set_state :continue
        },
        Button.new(325, 360, ConnecMan.default_font, ConnecMan.text(:back), :main_btn3, 0xffffff, 0, 0xffff00, 0xff8000) {
          set_state :main
        }
      ],
      instructions: []
    }

    @saves = []
    save_files = Dir["#{ConnecMan.saves_path}/*"]
    save_files.each do |s|
      @saves << s.split('/')[-1]
      set_load_buttons
    end

    @board1 = Res.img(:main_Board)
    @board2 = Res.img(:main_Board2)

    set_state :main, false
    ConnecMan.play_song(@bgm_start)
  end

  def set_state(state, play_sound = true)
    @state = state
    @title = ConnecMan.text(state)
    ConnecMan.play_sound('1') if play_sound
  end

  def set_load_buttons(start_index = 0)
    @load_start_index = start_index
    @controls[:continue] = []
    if @saves.size > 4 && start_index > 0
      @controls[:continue] << Button.new(384, 224, nil, nil, :main_btnUp) {
        set_load_buttons(@load_start_index - 1)
      }
    end
    limit = [@saves.size, 4].min - 1
    (0..limit).each do |i|
      name = @saves[start_index + i]
      @controls[:continue] << Button.new(325, 240 + i * 40, ConnecMan.default_font, name, :main_btn3, 0xffffff, 0, 0xffff00, 0xff8000) {
        ConnecMan.load_game(name)
      }
    end
    if @saves.size > 4 && start_index < @saves.size - 4
      @controls[:continue] << Button.new(384, 396, nil, nil, :main_btnDown) {
        set_load_buttons(@load_start_index + 1)
      }
    end
    @controls[:continue] << Button.new(325, 420, ConnecMan.default_font, ConnecMan.text(:back), :main_btn3, 0xffffff, 0, 0xffff00, 0xff8000) {
      set_state :play
    }
  end

  def update
    @controls[@state].each(&:update)
  end

  def draw
    @bg_start.draw(0, 0, 0)

    @controls[:main].each(&:draw)

    board = case @state
            when :play, :continue
              @board1
            when :instructions
              @board2
            end
    if board
      y = (Const::SCR_H - board.height) / 2
      board.draw((Const::SCR_W - board.width) / 2, y, 0)
      ConnecMan.default_font.draw_text_rel(@title, Const::SCR_W / 2, y + 25, 0, 0.5, 0, 1, 1, 0xffffff00)
    end

    @controls[@state].each(&:draw) if @state != :main
  end
end
