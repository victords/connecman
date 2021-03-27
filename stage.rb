class Stage
  OVERLAY_COLOR = 0x64000000
  
  def initialize(num)
    data = File.read("#{Res.prefix}levels/#{'%02d' % num}.cman").split('#')
    general = data[0].split(',')
    @time_left = general[1].to_i
    @rows = general[2].to_i
    @cols = general[3].to_i
    bgm = general[4]
    @word = data[1] if general[0] == '1'
    item_amounts = data[2].split(',').map(&:to_i)
    
    puts "time: #{@time_left}, rows: #{@rows}, cols: #{@cols}"
    puts "WT: #{item_amounts[0]}, HG: #{item_amounts[1]}, DY: #{item_amounts[2]}"
    
    world = (num - 1) / 6 + 1
    @bg = Res.img("main_Background#{world}", false, false, '.jpg')
    @panel = Res.img(:main_Panel)
    @menu = Res.img("main_Menu#{world}")
    @font = ConnecMan.image_font
    
    @buttons = {
      main: [
        Button.new(325, 550, nil, nil, :main_btn1) {
          @state = :paused
        }
      ],
      dead: [
        Button.new(245, 550, nil, nil, :main_btn1) {
          
        },
        Button.new(405, 550, nil, nil, :main_btn1) {
          ConnecMan.back_to_world_map
        }
      ],
      paused: [
        Button.new(325, 240, nil, nil, :main_btn1) {
          @state = :main
        },
        Button.new(325, 280, nil, nil, :main_btn1) {

        },
        Button.new(325, 320, nil, nil, :main_btn1) {

        },
        Button.new(325, 360, nil, nil, :main_btn1) {
          @state = :confirm
        }
      ],
      confirm: [
        Button.new(325, 280, nil, nil, :main_btn1) {
          ConnecMan.back_to_world_map
        },
        Button.new(325, 320, nil, nil, :main_btn1) {
          @state = :paused
        }
      ]
    }
    @button_texts = {
      main: [:menu],
      dead: [:restart, :exit],
      paused: [:resume, :restart, :options, :exit],
      confirm: [:yes, :no]
    }
    
    @state = :main
    
    ConnecMan.play_song(Res.song("Main#{bgm}", false, '.mp3'))
  end
  
  def update
    @buttons[@state].each(&:update)
  end
  
  def draw_buttons(state)
    @buttons[state].each_with_index do |b, i|
      b.draw
      @font.draw_text_rel(ConnecMan.text(@button_texts[state][i]).upcase, b.x + b.w / 2, b.y + b.h / 2, 0, 0.5, 0.5, 0.5, 0.5, 0xff000000)
    end
  end
  
  def draw
    @bg.draw(0, 0, 0)
    @panel.draw(0, 480, 0)
    
    if @state == :paused || @state == :confirm
      draw_buttons(:main)
      G.window.draw_quad(0, 0, OVERLAY_COLOR,
                         0, Const::SCR_H, OVERLAY_COLOR,
                         Const::SCR_W, 0, OVERLAY_COLOR,
                         Const::SCR_W, Const::SCR_H, OVERLAY_COLOR, 0)
      @menu.draw((Const::SCR_W - @menu.width) / 2, (Const::SCR_H - @menu.height) / 2, 0)
      @font.draw_text_rel(ConnecMan.text(@state), Const::SCR_W / 2, (Const::SCR_H - @menu.height) / 2 + 25, 0, 0.5, 0, 0.5, 0.5, 0xff000000)
    end
    draw_buttons(@state)
  end
end
