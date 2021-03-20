require_relative 'global'

class Menu
  def initialize
    @bg_start = Res.img(:main_BackgroundStart, true, false, '.jpg')
    @bgm_start = Res.song(:Opening, true, '.mp3')
  end

  def show_main_menu
    @state = :main
    ConnecMan.play_song(@bgm_start)
  end

  def draw
    case @state
    when :main
      @bg_start.draw(0, 0, 0)
    end
  end
end
