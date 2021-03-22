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
          set_paging(:instructions, :main, 9)
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
          set_continue_buttons
          set_state :continue
        },
        Button.new(325, 360, ConnecMan.default_font, ConnecMan.text(:back), :main_btn3, 0xffffff, 0, 0xffff00, 0xff8000) {
          set_state :main
        }
      ],
      more: [
        Button.new(325, 220, ConnecMan.default_font, ConnecMan.text(:about), :main_btn3, 0xffffff, 0,0xffff00, 0xff8000) {
          set_paging(:about, :more, 3)
          set_state :about
        },
        Button.new(325, 280, ConnecMan.default_font, ConnecMan.text(:hall_of_fame), :main_btn3, 0xffffff, 0,0xffff00, 0xff8000) {
          set_state :hall_of_fame
        },
        Button.new(325, 340, ConnecMan.default_font, ConnecMan.text(:credits), :main_btn3, 0xffffff, 0,0xffff00, 0xff8000) {
          set_state :credits
        },
        Button.new(325, 400, ConnecMan.default_font, ConnecMan.text(:back), :main_btn3, 0xffffff, 0,0xffff00, 0xff8000) {
          set_state :main
        },
      ],
      hall_of_fame: [
        Button.new(325, 450, ConnecMan.default_font, ConnecMan.text(:back), :main_btn3, 0xffffff, 0,0xffff00, 0xff8000) {
          set_state :more
        },
      ],
      credits: [
        Button.new(325, 450, ConnecMan.default_font, ConnecMan.text(:back), :main_btn3, 0xffffff, 0,0xffff00, 0xff8000) {
          set_state :more
        },
      ]
    }

    @saves = []
    hall_of_fame = []
    save_files = Dir["#{ConnecMan.saves_path}/*"]
    save_files.each do |s|
      name = s.split('/')[-1]
      @saves << name
      data = File.read(s).split('#', -1)
      total_score = data[2].split(',').map(&:to_i).sum
      hall_of_fame << { name: name, score: total_score }
    end
    @hall_of_fame = hall_of_fame[0..9].sort! { |a, b| b[:score] <=> a[:score] }

    @board1 = Res.img(:main_Board)
    @board2 = Res.img(:main_Board2)
    @instructions_images = Res.imgs(:main_instructions, 1, 8)

    set_state :main, false
    ConnecMan.play_song(@bgm_start)
  end

  def set_state(state, play_sound = true)
    @state = state
    @title = ConnecMan.text(state)
    ConnecMan.play_sound('1') if play_sound
  end

  def set_continue_buttons(start_index = 0)
    @page_index = start_index
    @controls[:continue] = []
    if @saves.size > 4 && start_index > 0
      @controls[:continue] << Button.new(384, 224, nil, nil, :main_btnUp) {
        set_continue_buttons(@page_index - 1)
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
        set_continue_buttons(@page_index + 1)
      }
    end
    @controls[:continue] << Button.new(325, 420, ConnecMan.default_font, ConnecMan.text(:back), :main_btn3, 0xffffff, 0, 0xffff00, 0xff8000) {
      set_state :play
    }
  end

  def set_paging(state, prev_state, page_count, page = 0)
    @page_index = page
    @controls[state] = []
    if page > 0
      @controls[state] << Button.new(155, 450, ConnecMan.default_font, ConnecMan.text(:previous), :main_btn3, 0xffffff, 0, 0xffff00, 0xff8000) {
        set_paging(state, prev_state, page_count, @page_index - 1)
      }
    end
    @controls[state] << Button.new(325, 450, ConnecMan.default_font, ConnecMan.text(:back), :main_btn3, 0xffffff, 0, 0xffff00, 0xff8000) {
      set_state prev_state
    }
    if page < page_count - 1
      @controls[state] << Button.new(495, 450, ConnecMan.default_font, ConnecMan.text(:next), :main_btn3, 0xffffff, 0, 0xffff00, 0xff8000) {
        set_paging(state, prev_state, page_count, @page_index + 1)
      }
    end
  end

  def update
    @controls[@state].each(&:update)
  end

  def draw
    @bg_start.draw(0, 0, 0)

    @controls[:main].each(&:draw)

    board = case @state
            when :play, :continue, :more
              @board1
            when :instructions, :about, :hall_of_fame, :credits
              @board2
            end
    if board
      y = (Const::SCR_H - board.height) / 2
      board.draw((Const::SCR_W - board.width) / 2, y, 0)
      ConnecMan.default_font.draw_text_rel(@title, Const::SCR_W / 2, y + 25, 0, 0.5, 0, 1, 1, 0xffffff00)
    end

    if @state == :instructions
      ConnecMan.text_helper.write_breaking(ConnecMan.text("instructions_#{@page_index}"), 120, 190, 560, :justified, 0xffffff)
      if @page_index < 5
        @instructions_images[@page_index].draw(120, 330, 0)
      elsif @page_index == 5
        @instructions_images[@page_index + ConnecMan.langs.index(ConnecMan.language)].draw(120, 330, 0)
      end
    elsif @state == :about
      ConnecMan.text_helper.write_breaking(ConnecMan.text("about_#{@page_index}"), 120, 190, 560, :justified, 0xffffff)
    elsif @state == :hall_of_fame
      @hall_of_fame.each_with_index do |h, i|
        ConnecMan.text_helper.write_line(h[:name], 180, 155 + i * 30, :left, 0xffffff)
        ConnecMan.text_helper.write_line(h[:score].to_s, 620, 155 + i * 30, :right, 0xffffff)
      end
    end

    @controls[@state].each(&:draw) if @state != :main
  end
end
