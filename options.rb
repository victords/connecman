class Options
  class << self
    def initialize(&back_action)
      @controls = []
      (0..5).each do |i|
        @controls << Button.new(620, 195 + i * 37 + (i > 2 ? 35 : 0), nil, nil, :main_btnUp) {
          change_setting(i, true)
        }
        @controls << Button.new(620, 211 + i * 37 + (i > 2 ? 35 : 0), nil, nil, :main_btnDown) {
          change_setting(i, false)
        }
      end
      @controls << Button.new(240, 450, ConnecMan.default_font, ConnecMan.text(:save), :main_btn3, 0xffffff, 0, 0xffff00, 0xff8000) {
        ConnecMan.save_options
        back_action.call
      }
      @controls << Button.new(410, 450, ConnecMan.default_font, ConnecMan.text(:cancel), :main_btn3, 0xffffff, 0, 0xffff00, 0xff8000) {
        revert_options
        back_action.call
      }

      @prev_options = [
        ConnecMan.language,
        ConnecMan.shortcut_keys,
        ConnecMan.mouse_control,
        ConnecMan.full_screen,
        ConnecMan.music_volume,
        ConnecMan.sound_volume
      ]
    end

    def change_setting(index, up)
      case index
      when 0
        ConnecMan.change_language(up ? -1 : 1)
      when 1
        ConnecMan.shortcut_keys = !ConnecMan.shortcut_keys
      when 2
        ConnecMan.mouse_control = !ConnecMan.mouse_control
      when 3
        ConnecMan.full_screen = !ConnecMan.full_screen
        G.window.fullscreen = ConnecMan.full_screen
      when 4
        if up && ConnecMan.music_volume < 10
          ConnecMan.music_volume += 1
        elsif !up && ConnecMan.music_volume > 0
          ConnecMan.music_volume -= 1
        end
      when 5
        if up && ConnecMan.sound_volume < 10
          ConnecMan.sound_volume += 1
        elsif !up && ConnecMan.sound_volume > 0
          ConnecMan.sound_volume -= 1
        end
      end
    end

    def revert_options
      ConnecMan.language = @prev_options[0]
      ConnecMan.shortcut_keys = @prev_options[1]
      ConnecMan.mouse_control = @prev_options[2]
      ConnecMan.full_screen = @prev_options[3]
      ConnecMan.music_volume = @prev_options[4]
      ConnecMan.sound_volume = @prev_options[5]
      G.window.fullscreen = ConnecMan.full_screen
    end

    def update
      @controls.each(&:update)
    end

    def draw
      font = ConnecMan.default_font
      font.draw_text(ConnecMan.text(:general), 150, 170, 0, 1, 1, 0xffffff00)
      font.draw_text(ConnecMan.text(:language), 160, 205, 0, 0.75, 0.75, 0xffffffff)
      font.draw_text_rel(ConnecMan.text(:lang_name), 600, 205, 0, 1, 0, 0.75, 0.75, 0xffffffff)
      font.draw_text(ConnecMan.text(:shortcut_keys), 160, 242, 0, 0.75, 0.75, 0xffffffff)
      font.draw_text_rel(ConnecMan.text(ConnecMan.shortcut_keys ? :on : :off), 600, 242, 0, 1, 0, 0.75, 0.75, 0xffffffff)
      font.draw_text(ConnecMan.text(:controls), 160, 279, 0, 0.75, 0.75, 0xffffffff)
      font.draw_text_rel(ConnecMan.text(ConnecMan.mouse_control ? :mouse : :keyboard), 600, 279, 0, 1, 0, 0.75, 0.75, 0xffffffff)
      font.draw_text(ConnecMan.text(:audio_graphics), 150, 314, 0, 1, 1, 0xffffff00)
      font.draw_text(ConnecMan.text(:full_screen), 160, 349, 0, 0.75, 0.75, 0xffffffff)
      font.draw_text_rel(ConnecMan.text(ConnecMan.full_screen ? :on : :off), 600, 349, 0, 1, 0, 0.75, 0.75, 0xffffffff)
      font.draw_text(ConnecMan.text(:music_volume), 160, 386, 0, 0.75, 0.75, 0xffffffff)
      font.draw_text_rel(ConnecMan.music_volume.to_s, 600, 386, 0, 1, 0, 0.75, 0.75, 0xffffffff)
      font.draw_text(ConnecMan.text(:sound_volume), 160, 423, 0, 0.75, 0.75, 0xffffffff)
      font.draw_text_rel(ConnecMan.sound_volume.to_s, 600, 423, 0, 1, 0, 0.75, 0.75, 0xffffffff)

      @controls.each(&:draw)
    end
  end
end
