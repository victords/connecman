require_relative 'options'

class Menu < Controller
  def initialize
    super
    @bg_start = Res.img(:main_BackgroundStart, true, false, '.jpg')

    @controls = {
      main: [
        CButton.new(90, 225, ConnecMan.default_font, :play, :main_btn2, 0x333300, 0, 0x666633, 0x333300, false, true, 8) {
          set_state :play
        },
        CButton.new(90, 265, ConnecMan.default_font, :instructions, :main_btn2, 0x333300, 0, 0x666633, 0x333300, false, true, 8) {
          set_paging(:instructions, :main, 9)
          set_state :instructions
        },
        CButton.new(90, 305, ConnecMan.default_font, :options, :main_btn2, 0x333300, 0, 0x666633, 0x333300, false, true, 8) {
          Options.initialize {
            set_state :main
          }
          set_state :options
        },
        CButton.new(90, 345, ConnecMan.default_font, :more, :main_btn2, 0x333300, 0, 0x666633, 0x333300, false, true, 8) {
          set_state :more
        },
        CButton.new(90, 405, ConnecMan.default_font, :exit, :main_btn2, 0x333300, 0, 0x666633, 0x333300, false, true, 8) {
          exit(0)
        }
      ],
      play: [
        CButton.new(325, 240, ConnecMan.default_font, :new_game, :main_btn3, 0xffffff, 0, 0xffff00, 0xff8000) {
          ConnecMan.new_game
        },
        CButton.new(325, 300, ConnecMan.default_font, :continue, :main_btn3, 0xffffff, 0, 0xffff00, 0xff8000) {
          set_continue_buttons
          set_state :continue
        },
        CButton.new(325, 360, ConnecMan.default_font, :back, :main_btn3, 0xffffff, 0, 0xffff00, 0xff8000) {
          set_state :main
        }
      ],
      more: [
        CButton.new(325, 220, ConnecMan.default_font, :about, :main_btn3, 0xffffff, 0,0xffff00, 0xff8000) {
          set_paging(:about, :more, 3)
          set_state :about
        },
        CButton.new(325, 280, ConnecMan.default_font, :hall_of_fame, :main_btn3, 0xffffff, 0,0xffff00, 0xff8000) {
          set_state :hall_of_fame
        },
        CButton.new(325, 340, ConnecMan.default_font, :credits, :main_btn3, 0xffffff, 0,0xffff00, 0xff8000) {
          set_state :credits
        },
        CButton.new(325, 400, ConnecMan.default_font, :back, :main_btn3, 0xffffff, 0,0xffff00, 0xff8000) {
          set_state :main
        },
      ],
      hall_of_fame: [
        CButton.new(325, 450, ConnecMan.default_font, :back, :main_btn3, 0xffffff, 0,0xffff00, 0xff8000) {
          set_state :more
        },
      ],
      credits: [
        CButton.new(325, 450, ConnecMan.default_font, :back, :main_btn3, 0xffffff, 0,0xffff00, 0xff8000) {
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
      if data[0] == '!'
        total_score = data[2].split(',').map(&:to_i).sum
        hall_of_fame << { name: name, score: total_score }
      end
    end
    @hall_of_fame = hall_of_fame[0..9].sort! { |a, b| b[:score] <=> a[:score] }

    @board1 = Res.img(:main_Board)
    @board2 = Res.img(:main_Board2)
    @instructions_images = Res.imgs(:main_instructions, 1, 6)

    set_state :main, false
  end

  def set_state(state, play_sound = true)
    @state = state
    if @state == :options
      reset_current_button
      @cursor_points = Options.get_cursor_points
      @cursor_point_index = -1
      set_cursor_point(0)
    elsif @state != :instructions && @state != :about
      set_group(@controls[@state])
    end
    ConnecMan.play_sound('1') if play_sound
  end

  def set_continue_buttons(start_index = 0)
    @page_index = start_index
    @controls[:continue] = []
    if @saves.size > 4 && start_index > 0
      @controls[:continue] << Button.new(384, 204, nil, nil, :main_btnUp) {
        set_continue_buttons(@page_index - 1)
      }
    end
    limit = [@saves.size, 4].min - 1
    (0..limit).each do |i|
      name = @saves[start_index + i]
      @controls[:continue] << Button.new(325, 220 + i * 40, ConnecMan.default_font, name, :main_btn3, 0xffffff, 0, 0xffff00, 0xff8000) {
        ConnecMan.load_game(name)
      }
    end
    if @saves.size > 4 && start_index < @saves.size - 4
      @controls[:continue] << Button.new(384, 376, nil, nil, :main_btnDown) {
        set_continue_buttons(@page_index + 1)
      }
    end
    @controls[:continue] << Button.new(325, 420, ConnecMan.default_font, ConnecMan.text(:back), :main_btn3, 0xffffff, 0, 0xffff00, 0xff8000) {
      set_state :play
    }
    set_group(@controls[:continue])
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
        set_cursor_point(@cursor_points.size > 2 ? 2 : 1)
      }
    end
    set_group(@controls[state], true)
  end

  def update
    super
    if @state == :options
      Options.update
    else
      @controls[@state].each(&:update) if ConnecMan.mouse_control
    end
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
      ConnecMan.default_font.draw_text_rel(ConnecMan.text(@state), Const::SCR_W / 2, y + 25, 0, 0.5, 0, 1, 1, 0xffffff00)
    end

    if @state == :continue && @saves.empty?
      ConnecMan.default_font.draw_text_rel(ConnecMan.text(:no_saved_games), Const::SCR_W / 2, Const::SCR_H / 2, 0, 0.5, 0, 1, 1, 0xffffffff)
    elsif @state == :instructions
      ConnecMan.text_helper.write_breaking(ConnecMan.text("instructions_#{@page_index}"), 120, 190, 560, :justified, 0xffffff)
      @instructions_images[@page_index].draw(120, 330, 0) if @page_index <= 5
      if @page_index == 5
        ConnecMan.text_helper.write_line(ConnecMan.text(:inst_image_1), 343, 370, :right, 0xffffff)
        ConnecMan.text_helper.write_line(ConnecMan.text(:inst_image_2), 465, 363, :left, 0xffffff)
        ConnecMan.text_helper.write_line(ConnecMan.text(:inst_image_3), 452, 406, :left, 0xffffff)
      end
    elsif @state == :about
      ConnecMan.text_helper.write_breaking(ConnecMan.text("about_#{@page_index}"), 120, 190, 560, :justified, 0xffffff, 255, 0, 1, 1)
    elsif @state == :hall_of_fame
      if @hall_of_fame.empty?
        ConnecMan.default_font.draw_text_rel(ConnecMan.text(:no_players), Const::SCR_W / 2, Const::SCR_H / 2, 0, 0.5, 0, 1, 1, 0xffffffff)
      else
        @hall_of_fame.each_with_index do |h, i|
          ConnecMan.text_helper.write_line(h[:name], 180, 155 + i * 30, :left, 0xffffff)
          ConnecMan.text_helper.write_line(h[:score].to_s, 620, 155 + i * 30, :right, 0xffffff)
        end
      end
    elsif @state == :credits
      ConnecMan.text_helper.write_breaking(ConnecMan.text(:credits_info), Const::SCR_W / 2, 190, 560, :center, 0xffffff, 255, 0, 0.75, 0.75)
    end

    if @state == :options
      Options.draw
    else
      @controls[@state].each(&:draw) if @state != :main
    end
    
    ConnecMan.text_helper.write_line('v1.1.1', 790, 570, :right)

    super
  end
end
