require_relative 'elements'
require_relative 'options'

class CEffect < Effect
  def initialize(x, y, img, sprite_cols, sprite_rows, interval, indices, lifetime)
    super(x, y, img, sprite_cols, sprite_rows, interval, indices, lifetime)
    @img_index = indices[0]
  end
end

class Stage
  BLACK = 0xff000000
  WHITE = 0xffffffff
  OVERLAY_COLOR = 0x64000000
  
  def initialize(num)
    world = (num - 1) / 6 + 1
    @bg = Res.img("main_Background#{world}", false, false, '.jpg')
    @highlight = Res.img(:main_CursorHighlight)
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
          @pieces[row] = {} if @pieces[row].nil?
          @pieces[row][col] = Rock.new(row, col, false)
          col += 1
          if col == @cols
            row += 1
            col = 0
          end
        end
      when 'f'
        @pieces[row] = {} if @pieces[row].nil?
        @pieces[row][col] = Rock.new(row, col, true)
        col += 1
      when 'i', 'y'
        @pieces[row] = {} if @pieces[row].nil?
        @pieces[row][col] = IceBlock.new(row, col, token[1].nil? ? nil : token[1].to_i)
        col += 1
      when /[rgbcqwoszn]/
        piece = Piece.new(row, col, el_types.index(token[0]) - 5, symbols.index(token[1]))
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
    @effects = []
    @state = :main
    
    ConnecMan.play_song(Res.song("Main#{bgm}", false, '.mp3'))
  end
  
  def find_path(piece1, piece2)
    @paths = []
    find_path_r(piece1.row, piece1.col, piece2)
    return nil if @paths.empty?
    path = @paths.min { |a, b| a.size <=> b.size }
    path << [piece2.row, piece2.col]
  end
  
  def find_path_r(row, col, dest, turn_count = -1, dir = -1, path = [], step_count = 0)
    return if row < 0 || col < 0 || row >= @rows || col >= @cols
    
    if dir > -1 && @pieces[row] && @pieces[row][col]
      @paths << path[0...step_count] if @pieces[row][col] == dest
      return
    end

    path[step_count] = [row, col]
    
    find_path_r(row - 1, col, dest, dir == 0 ? turn_count : turn_count + 1, 0, path, step_count + 1) if (dir == 0 || turn_count < 2) && dir != 2
    find_path_r(row, col + 1, dest, dir == 1 ? turn_count : turn_count + 1, 1, path, step_count + 1) if (dir == 1 || turn_count < 2) && dir != 3
    find_path_r(row + 1, col, dest, dir == 2 ? turn_count : turn_count + 1, 2, path, step_count + 1) if (dir == 2 || turn_count < 2) && dir != 0
    find_path_r(row, col - 1, dest, dir == 3 ? turn_count : turn_count + 1, 3, path, step_count + 1) if (dir == 3 || turn_count < 2) && dir != 1
  end
  
  def add_path_effects(path)
    path.each_with_index do |p, i|
      pr = path[i - 1]
      nx = path[i + 1]
      type = if i == 0 || i == path.size - 1
               6
             elsif pr[0] == p[0]
               if nx[0] == p[0]
                 0
               elsif nx[0] < p[0]
                 if pr[1] < p[1]
                   3
                 else
                   4
                 end
               elsif pr[1] < p[1]
                 2
               else
                 5
               end
             elsif pr[0] < p[0]
               if nx[0] == p[0]
                 if nx[1] < p[1]
                   3
                 else
                   4
                 end
               else
                 1
               end
             elsif nx[0] == p[0]
               if nx[1] < p[1]
                 2
               else
                 5
               end
             else
               1
             end
      @effects << CEffect.new(p[1] * Const::TILE_SIZE + @margin.x - 8, p[0] * Const::TILE_SIZE + @margin.y - 8, :fx_ways, 4, 2, 0, [type], 60)
    end
  end
  
  def add_piece_effect(piece)
    sym_img = piece.type == 9 ? :symbols_black : :symbols_white
    @effects << CEffect.new(piece.col * Const::TILE_SIZE + @margin.x, piece.row * Const::TILE_SIZE + @margin.y, :board_pieces, 5, 2, 0, [piece.type], 60)
    @effects << CEffect.new(piece.col * Const::TILE_SIZE + @margin.x, piece.row * Const::TILE_SIZE + @margin.y, sym_img, 8, 4, 0, [piece.symbol], 60)
  end
  
  def connect(piece)
    if piece.type >= 3 && piece.type <= 5
      piece.change_type(piece.type - 3)
    else
      @pieces[piece.row][piece.col] = nil
    end
    check_melt(piece.row - 1, piece.col)
    check_melt(piece.row, piece.col + 1)
    check_melt(piece.row + 1, piece.col)
    check_melt(piece.row, piece.col - 1)
  end
  
  def check_melt(row, col)
    return unless @pieces[row] && @pieces[row][col].is_a?(IceBlock)
    @effects << Effect.new(col * Const::TILE_SIZE + @margin.x, row * Const::TILE_SIZE + @margin.y - 32, :fx_iceMelt, 5, 1, 10)
    @pieces[row][col] = nil
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
    
    @effects.reverse_each do |e|
      e.update
      @effects.delete(e) if e.dead
    end
    
    row = (Mouse.y - @margin.y) / Const::TILE_SIZE
    col = (Mouse.x - @margin.x) / Const::TILE_SIZE
    if @pieces[row] && @pieces[row][col] && @pieces[row][col].selectable
      piece = @pieces[row][col]
      @hovered_piece = piece
      if Mouse.button_pressed?(:left)
        if @selected_piece
          if piece == @selected_piece
            @selected_piece = nil
          elsif piece.match?(@selected_piece)
            path = find_path(piece, @selected_piece)
            if path
              add_path_effects(path)
              add_piece_effect(piece)
              add_piece_effect(@selected_piece)
              connect(piece)
              connect(@selected_piece)
              ConnecMan.play_sound('5')
              @selected_piece = @hovered_piece = nil
            else
              @selected_piece = piece
            end
          else
            @selected_piece = piece
          end
        else
          @selected_piece = piece
        end
      end
    else
      @selected_piece = nil if Mouse.button_pressed?(:left)
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
    @pieces.each do |_, row|
      row.each do |_, cell|
        cell.draw(@margin) if cell
      end if row
    end
    @highlight.draw(@hovered_piece.col * Const::TILE_SIZE + @margin.x, @hovered_piece.row * Const::TILE_SIZE + @margin.y, 0) if @hovered_piece
    @highlight.draw(@selected_piece.col * Const::TILE_SIZE + @margin.x, @selected_piece.row * Const::TILE_SIZE + @margin.y, 0, 1, 1, 0xffffff00) if @selected_piece
    @effects.each(&:draw)

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
