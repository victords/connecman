require_relative 'elements'
require_relative 'options'

class Stage
  BLACK = 0xff000000
  WHITE = 0xffffffff
  OVERLAY_COLOR = 0x64000000
  
  def initialize(num)
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
          @confirm_exit = false
          @state = :confirm
        },
        Button.new(325, 320, nil, nil, :main_btn1) {
          Options.initialize {
            @state = :paused
          }
          @state = :options
        },
        Button.new(325, 360, nil, nil, :main_btn1) {
          @confirm_exit = true
          @state = :confirm
        }
      ],
      confirm: [
        Button.new(325, 280, nil, nil, :main_btn1) {
          if @confirm_exit
            ConnecMan.back_to_world_map
          else
            start(num)
          end
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
    
    start(num)
  end
  
  def start(num)
    data = File.read("#{Res.prefix}levels/#{'%02d' % num}.cman").split('#')
    general = data[0].split(',')
    @time_left = general[1].to_i
    @rows = general[2].to_i
    @cols = general[3].to_i
    bgm = general[4]
    @word = data[1] if general[0] == '1'
    item_amounts = data[2].split(',').map(&:to_i)
    @items = {}
    @items[:waveTransmitter] = item_amounts[0] if item_amounts[0] > 0
    @items[:hourglass] = item_amounts[1] if item_amounts[1] > 0
    @items[:dynamite] = item_amounts[2] if item_amounts[2] > 0

    row = 0; col = 0; i = 0
    el_types = '%kfiyrgbcqwoszn'
    symbols = 'ABKDEFGHIJLMNOPRSTUVXZ1234567890'
    @elements = []
    @pieces = {}
    while i < data[3].size
      token = ''
      begin
        token += data[3][i]
        i += 1
      end until data[3][i].nil? || el_types.include?(data[3][i])

      case token[0]
      when '%'
        col += token[1..-1].to_i
        if col >= @cols
          row += (col / @cols)
          col %= @cols
        end
      when 'k'
        amount = token[1..-1].to_i
        amount.times do
          @elements << Rock.new(row, col, false)
          col += 1
          if col == @cols
            row += 1
            col = 0
          end
        end
      when 'f'
        @elements << Rock.new(row, col, true)
        col += 1
      when 'i', 'y'
        @elements << IceBlock.new(row, col, token[1].nil? ? nil : token[1].to_i)
        col += 1
      when /[rgbcqwoszn]/
        @elements << (piece = Piece.new(row, col, el_types.index(token[0]) - 5, symbols.index(token[1])))
        piece.set_movable(:up) if token.include?('!')
        piece.set_movable(:rt) if token.include?('@')
        piece.set_movable(:dn) if token.include?('$')
        piece.set_movable(:lf) if token.include?('&')
        @pieces[row] = {} if @pieces[row].nil?
        @pieces[row][col] = piece
        col += 1
      end

      if col == @cols
        row += 1
        col = 0
      end
    end

    @margin = MiniGL::Vector.new((Const::SCR_W - @cols * Const::TILE_SIZE) / 2, (480 - @rows * Const::TILE_SIZE) / 2)
    @score = 0
    @timer = 0
    @state = :main
    
    ConnecMan.play_song(Res.song("Main#{bgm}", false, '.mp3'))
  end
  
  def update
    if @state == :options
      Options.update
      return
    end
    
    @buttons[@state].each(&:update)
    return unless @state == :main
    
    @timer += 1
    if @timer == 60
      @time_left -= 1
      @timer = 0
    end
    
    row = (Mouse.y - @margin.y) / Const::TILE_SIZE
    col = (Mouse.x - @margin.x) / Const::TILE_SIZE
    if @pieces[row] && @pieces[row][col]
      piece = @pieces[row][col]
      if Mouse.button_pressed?(:left)
        if @selected_piece
          if piece == @selected_piece
            @selected_piece.state = :mouse_over
            @selected_piece = nil
          elsif piece.match?(@selected_piece)
            puts "check pair"
          else
            @selected_piece.state = nil
            @selected_piece = piece
            @selected_piece.state = :selected
          end
        else
          @selected_piece = piece
          @selected_piece.state = :selected
        end
      else
        @hovered_piece.state = nil if @hovered_piece && @hovered_piece.state != :selected
        @hovered_piece = piece
        @hovered_piece.state = :mouse_over if @hovered_piece.state != :selected
      end
    else
      @hovered_piece.state = nil if @hovered_piece && @hovered_piece.state != :selected
      @hovered_piece = nil
    end
  end
  
  def draw_buttons(state)
    @buttons[state].each_with_index do |b, i|
      b.draw
      @font.draw_text_rel(ConnecMan.text(@button_texts[state][i]).upcase, b.x + b.w / 2, b.y + b.h / 2, 0, 0.5, 0.5, 0.5, 0.5, BLACK)
    end
  end
  
  def draw_overlay
    G.window.draw_quad(0, 0, OVERLAY_COLOR,
                       0, Const::SCR_H, OVERLAY_COLOR,
                       Const::SCR_W, 0, OVERLAY_COLOR,
                       Const::SCR_W, Const::SCR_H, OVERLAY_COLOR, 0)
  end
  
  def draw
    @bg.draw(0, 0, 0)
    @elements.each do |el|
      el.draw(@margin)
    end

    @panel.draw(0, 480, 0)
    @font.draw_text(ConnecMan.text(:score) + @score.to_s, 50, 502, 0, 0.5, 0.5, WHITE)
    @font.draw_text(ConnecMan.text(:time) + @time_left.to_s, 50, 558, 0, 0.5, 0.5, WHITE)
    @items.each_with_index do |(k, v), i|
      Res.img("icon_#{k}").draw(660, 500 + i * 28, 0)
      @font.draw_text(v.to_s, 690, 502 + i * 28, 0, 0.5, 0.5, WHITE)
    end
    
    if @state == :options
      draw_buttons(:main)
      draw_overlay
      Options.draw
    elsif @state == :paused || @state == :confirm
      draw_buttons(:main)
      draw_overlay
      @menu.draw((Const::SCR_W - @menu.width) / 2, (Const::SCR_H - @menu.height) / 2, 0)
      @font.draw_text_rel(ConnecMan.text(@state), Const::SCR_W / 2, (Const::SCR_H - @menu.height) / 2 + 25, 0, 0.5, 0, 0.5, 0.5, BLACK)
    end
    draw_buttons(@state) unless @state == :options
  end
end
