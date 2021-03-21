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
          set_state :load
        },
        Button.new(325, 360, ConnecMan.default_font, ConnecMan.text(:back), :main_btn3, 0xffffff, 0, 0xffff00, 0xff8000) {
          set_state :main
        }
      ]
    }

    # TODO load saved games

    @state = :main
    ConnecMan.play_song(@bgm_start)
  end

  def set_state(state)
    @state = state
    ConnecMan.play_sound('1')
  end

  def update
    @controls[@state].each(&:update)
  end

  def draw
    @bg_start.draw(0, 0, 0)

    @controls[@state].each(&:draw)
  end
end
