require_relative 'elements'
require_relative 'options'

class CEffect < Effect
  def initialize(x, y, img, sprite_cols, sprite_rows, interval, indices, lifetime, color = nil)
    super(x, y, img, sprite_cols, sprite_rows, interval, indices, lifetime)
    @img_index = indices[0]
    @color = color || 0xffffffff
  end
  
  def draw
    @img[@img_index].draw(@x, @y, 0, 1, 1, @color)
  end
end

class HourglassEffect < Effect
  def initialize
    super(Const::SCR_W / 2, 240, :fx_hourglass, nil, nil, 0, nil, 60, '8')
    @angle = 0
  end
  
  def update
    super
    @angle += 1
  end
  
  def draw
    @img[0].draw_rot(@x, @y, 0, @angle, 0.5, 0.5, 1, 1, ((255 * (1 - @angle.to_f / 60)).floor << 24) | 0xffffff)
  end
end

class TimerEffect
  attr_reader :dead
  
  def initialize
    @x = 250
    @y = 500
    @bg = Res.img(:fx_timerBg)
    @fill = Res.img(:fx_timerFill)
    @icon = Res.img(:icon_hourglass)
    @lifetime = Const::STOP_TIME_DURATION
  end
  
  def update
    @lifetime -= 1
    @dead = true if @lifetime == 0
  end
  
  def draw
    @bg.draw(@x, @y, 0)
    w = @lifetime / 6
    if w >= 2
      if w <= 10
        @fill.subimage(0, 0, w / 2, @fill.height).draw(@x, @y, 0)
        @fill.subimage(@fill.width - w + w / 2, 0, w - (w / 2), @fill.height).draw(@x + w / 2, @y, 0)
      else
        @fill.subimage(0, 0, 5, @fill.height).draw(@x, @y, 0)
        @fill.subimage(5, 0, 290, @fill.height).draw(@x + 5, @y, 0, (w - 10).to_f / 290, 1)
        @fill.subimage(@fill.width - 5, 0, 5, @fill.height).draw(@x + w - 5, @y, 0)
      end
    end
    @icon.draw(@x, @y, 0)
  end
end

class CSprite < Sprite
  attr_reader :img_id
  
  def initialize(x, y, img, sprite_cols, sprite_rows, index)
    super(x, y, img, sprite_cols, sprite_rows)
    @img_id = img
    @img_index = index
  end
end

class ItemEffect < GameObject
  attr_reader :dead
  
  def initialize(row, col, margin, type, index)
    super(col * Const::TILE_SIZE + margin.x + 4, row * Const::TILE_SIZE + margin.y + 4, 25, 25, "icon_#{type}")
    @aim = Vector.new(660, 500 + index * 28)
  end
  
  def update
    move_free(@aim, 5)
    if @speed.x == 0 && @speed.y == 0
      @dead = true
    end
  end
  
  def draw
    @img[0].draw(@x, @y, 0)
  end
end

class Stage < Controller
  BLACK = 0xff000000
  WHITE = 0xffffffff
  LIGHT_BLUE = 0xff99ccff
  YELLOW = 0xffffff00
  OVERLAY_COLOR = 0x64000000
  NISLED_WORDS = %w(FOND SEMI VEIN KORE)
  
  attr_reader :num
  
  def initialize(num)
    super()
    
    @num = num
    world = (num - 1) / 6 + 1
    @bg = Res.img("main_Background#{world}", false, false, '.jpg')
    @highlight = Res.img(:main_CursorHighlight)
    @panel = Res.img(:main_Panel)
    @board = Res.img(:main_Board2)
    @menu = Res.img("main_Menu#{world}")
    @font = ConnecMan.image_font
    # preload as tileable
    _ = Res.imgs(:fx_ways, 3, 2, false, '.png', false, true)
    _ = Res.imgs(:fx_specialWays, 3, 2, false, '.png', false, true)
    @frame_color = world == 4 ? WHITE : 0xff333333
    
    @buttons = {
      main: [
        Button.new(325, 550, nil, nil, :main_btn1) {
          set_state(:paused)
        }
      ],
      paused: [
        Button.new(325, 240, nil, nil, :main_btn1) {
          @cursor_position.y -= 480 if @cursor_position.y >= 480 && !ConnecMan.mouse_control
          set_state(:main)
        },
        Button.new(325, 280, nil, nil, :main_btn1) {
          @confirm_exit = false
          set_state(:confirm)
        },
        Button.new(325, 320, nil, nil, :main_btn1) {
          Options.initialize {
            set_state(:paused)
          }
          set_state(:options)
        },
        Button.new(325, 360, nil, nil, :main_btn1) {
          @confirm_exit = true
          set_state(:confirm)
        }
      ],
      confirm: [
        Button.new(325, 280, nil, nil, :main_btn1) {
          if @confirm_exit
            ConnecMan.back_to_world_map
          else
            restart
          end
        },
        Button.new(325, 320, nil, nil, :main_btn1) {
          set_state(:paused)
        }
      ],
      dead: [
        Button.new(245, 550, nil, nil, :main_btn1) {
          restart
        },
        Button.new(405, 550, nil, nil, :main_btn1) {
          ConnecMan.back_to_world_map
        }
      ]
    }
    @button_texts = {
      main: [:menu],
      dead: [:restart, :exit],
      paused: [:resume, :restart, :options, :exit],
      confirm: [:yes, :no]
    }
    
    ConnecMan.controls_changed += Proc.new {
      @cursor_position = Vector.new(@margin.x + Const::TILE_SIZE / 2, @margin.y + Const::TILE_SIZE / 2)
    }
    
    start
  end
  
  def start
    data = File.read("#{Res.prefix}levels/#{'%02d' % @num}.cman").split('#')
    general = data[0].split(',')
    @time_left = general[0].to_i
    @rows = general[1].to_i
    @cols = general[2].to_i
    bgm = general[3]
    item_amounts = data[1].split(',').map(&:to_i)
    @items = {}
    @items[:waveTransmitter] = item_amounts[0] if item_amounts[0] > 0
    @items[:hourglass] = item_amounts[1] if item_amounts[1] > 0
    @items[:dynamite] = item_amounts[2] if item_amounts[2] > 0
    @item_buttons = []
    @items.each_with_index do |(k, v), i|
      @item_buttons << Button.new(x: 660, y: 500 + i * 28, width: 25, height: 25) {
        use_item(k)
      }
    end

    @word = data[3].split(',').map(&:to_i) if data[3]
    
    row = 0; col = 0; i = 0
    el_types = '%kfiyrgbcqwoszn'
    symbols = 'ABKDEFGHIJLMNOPRSTUVXZ1234567890'
    @pieces = {}
    pieces_by_type = {}
    @pairs = {}
    @white_pieces = []
    @piece_count = 0
    @movable_piece_count = 0
    while i < data[2].size
      token = ''
      begin
        token += data[2][i]
        i += 1
      end until data[2][i].nil? || el_types.include?(data[2][i])

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
          set_piece(Rock.new(row, col, false))
          col += 1
          if col == @cols
            row += 1
            col = 0
          end
        end
      when 'f'
        set_piece(Rock.new(row, col, true))
        col += 1
      when 'i', 'y'
        set_piece(IceBlock.new(row, col, token[1].nil? ? nil : token[1].to_i))
        col += 1
      when /[rgbcqwoszn]/
        piece = Piece.new(row, col, el_types.index(token[0]) - 5, symbols.index(token[1]))
        piece.set_movable(:up) if token.include?('!')
        piece.set_movable(:rt) if token.include?('@')
        piece.set_movable(:dn) if token.include?('$')
        piece.set_movable(:lf) if token.include?('&')
        set_piece(piece)
        
        type = piece.type >= 3 && piece.type <= 5 ? piece.type - 3 : piece.type
        key = "#{type}|#{piece.symbol}"
        pieces_by_type[key] = [] if pieces_by_type[key].nil?
        @pairs[key] = [] if @pairs[key].nil?
        pieces_by_type[key].each do |p|
          @pairs[key] << [p, piece]
        end
        pieces_by_type[key] << piece
        if piece.type == 9
          @white_pieces[@word.index(piece.symbol)] = piece
        else
          @piece_count += 1
        end
        @movable_piece_count += 1 if piece.movable.any?
        
        col += 1
      end

      if col == @cols
        row += 1
        col = 0
      end
    end

    @margin = Vector.new((Const::SCR_W - @cols * Const::TILE_SIZE) / 2, (480 - @rows * Const::TILE_SIZE) / 2)
    @cursor_position = Vector.new(@margin.x + Const::TILE_SIZE / 2, @margin.y + Const::TILE_SIZE / 2)
    @score = {
      default: 0
    }
    @timer = 0
    @effects = []
    @score_effects = []
    @word_effects = []
    @action = :default
    set_state(:starting)
    
    ConnecMan.play_song(Res.song("Main#{bgm}", false, '.mp3'))
  end

  def restart
    ConnecMan.transition do
      start
    end
  end
  
  def set_state(state)
    @state = state
    if state == :options
      reset_current_button
      @cursor_points = Options.get_cursor_points
      @cursor_point_index = -1
      set_cursor_point(0)
    elsif state != :main
      set_group(@buttons[state] || [])
    end
  end
  
  def set_piece(piece)
    @pieces[piece.row] = {} if @pieces[piece.row].nil?
    @pieces[piece.row][piece.col] = piece
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
  
  def has_path?(piece1, piece2)
    find_path_r2(piece1.row, piece1.col, piece2)
  end

  def find_path_r2(row, col, dest, turn_count = -1, dir = -1)
    return if row < 0 || col < 0 || row >= @rows || col >= @cols

    if dir > -1 && @pieces[row] && @pieces[row][col]
      return @pieces[row][col] == dest
    end

    return true if (dir == 0 || turn_count < 2) && dir != 2 && find_path_r2(row - 1, col, dest, dir == 0 ? turn_count : turn_count + 1, 0)
    return true if (dir == 1 || turn_count < 2) && dir != 3 && find_path_r2(row, col + 1, dest, dir == 1 ? turn_count : turn_count + 1, 1)
    return true if (dir == 2 || turn_count < 2) && dir != 0 && find_path_r2(row + 1, col, dest, dir == 2 ? turn_count : turn_count + 1, 2)
    (dir == 3 || turn_count < 2) && dir != 1 && find_path_r2(row, col - 1, dest, dir == 3 ? turn_count : turn_count + 1, 3)
  end
  
  def add_path_effects(path, special = false, blue = false)
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
      if special
        if type == 6
          @word_effects << CSprite.new(p[1] * Const::TILE_SIZE + @margin.x - 8, p[0] * Const::TILE_SIZE + @margin.y - 8, :fx_specialWayExtremity, nil, nil, 0)
        else
          @word_effects << CSprite.new(p[1] * Const::TILE_SIZE + @margin.x, p[0] * Const::TILE_SIZE + @margin.y, :fx_specialWays, 3, 2, type)
        end
      else
        color = blue ? 0xff99ffff : WHITE
        if type == 6
          @effects << CEffect.new(p[1] * Const::TILE_SIZE + @margin.x - 8, p[0] * Const::TILE_SIZE + @margin.y - 8, :fx_wayExtremity, nil, nil, 0, [0], 60, color)
        else
          @effects << CEffect.new(p[1] * Const::TILE_SIZE + @margin.x, p[0] * Const::TILE_SIZE + @margin.y, :fx_ways, 3, 2, 0, [type], 60, color)
        end
      end
    end
  end
  
  def add_piece_effect(piece)
    sym_img = piece.type == 9 ? :symbols_black : :symbols_white
    @effects << CEffect.new(piece.col * Const::TILE_SIZE + @margin.x, piece.row * Const::TILE_SIZE + @margin.y, :board_pieces, 5, 2, 0, [piece.type], 60)
    @effects << CEffect.new(piece.col * Const::TILE_SIZE + @margin.x, piece.row * Const::TILE_SIZE + @margin.y, sym_img, 8, 4, 0, [piece.symbol], 60)
  end
  
  def add_wave_effects(piece1, piece2)
    @effects << Effect.new(piece1.col * Const::TILE_SIZE + @margin.x - 17, piece1.row * Const::TILE_SIZE + @margin.y - 42, :fx_waves, 5, 1, 7, nil, 60, '7')
    @effects << Effect.new(piece2.col * Const::TILE_SIZE + @margin.x - 1, piece2.row * Const::TILE_SIZE + @margin.y - 12, :fx_waveRec, 2, 1, 7, nil, 60)
  end

  def add_score_effect(row, col, score, decrease = false)
    t_s = Const::TILE_SIZE
    @score_effects << { x: col * t_s + t_s / 2 + @margin.x, y: row * t_s + t_s / 2 + @margin.y, text: score.to_s, color: decrease ? 0xffcc6450 : WHITE, lifetime: 60 }
  end
  
  def connect(piece)
    @score[:default] += piece.score
    @movable_piece_count -= 1 if piece.movable.any?
    if piece.type >= 3 && piece.type <= 5
      piece.change_type(piece.type - 3)
    else
      @pieces[piece.row][piece.col] = nil
      @piece_count -= 1
    end
    check_melt(piece.row - 1, piece.col)
    check_melt(piece.row, piece.col + 1)
    check_melt(piece.row + 1, piece.col)
    check_melt(piece.row, piece.col - 1)
    add_score_effect(piece.row, piece.col, piece.score)
  end
  
  def check_melt(row, col)
    return unless @pieces[row] && @pieces[row][col].is_a?(IceBlock)
    @effects << Effect.new(col * Const::TILE_SIZE + @margin.x, row * Const::TILE_SIZE + @margin.y - 32, :fx_iceMelt, 5, 1, 10)
    ConnecMan.play_sound('6')
    item_type = @pieces[row][col].item
    if item_type
      if @items[item_type]
        @items[item_type] += 1
      else
        @item_buttons << Button.new(x: 660, y: 500 + @items.size * 28, width: 25, height: 25) {
          use_item(item_type)
        }
        @items[item_type] = 1
      end
      @effects << ItemEffect.new(row, col, @margin, item_type, @items.keys.index(item_type))
    end
    @pieces[row][col] = nil
  end
  
  def update_pairs(piece1, piece2, strong1, strong2)
    key = piece1 ? "#{piece1.type}|#{piece1.symbol}" : nil
    if piece1 && !strong1 && @pairs[key]
      @pairs[key].reverse_each do |p|
        next unless p[0] == piece1 || p[1] == piece1
        @pairs[key].delete(p)
        @pairs.delete(key) if @pairs[key].empty?
      end
    end
    if piece2 && !strong2 && @pairs[key]
      @pairs[key].reverse_each do |p|
        next unless p[0] == piece2 || p[1] == piece2
        @pairs[key].delete(p)
        @pairs.delete(key) if @pairs[key].empty?
      end
    end
    
    has_movable_or_item = @movable_piece_count > 0 || @items[:waveTransmitter] || @items[:dynamite]
    return if !@pairs.empty? && has_movable_or_item
    
    if @word
      all_paths = true
      @white_pieces.each_with_index do |p, i|
        next if i == @white_pieces.size - 1
        unless has_path?(p, @white_pieces[i + 1])
          all_paths = false
          break
        end
      end
      return if all_paths
    end
    
    if @pairs.empty?
      unless @word
        if @piece_count > 0
          die
        else
          finish
        end
      end
    else
      @pairs.each do |_, ps|
        ps.each do |p|
          return if has_path?(p[0], p[1])
        end
      end
      die unless has_movable_or_item
    end
  end

  def select(piece)
    @selected_piece = piece
    @word_pieces = [piece] if piece.type == 9 && piece.symbol == @word[0]
  end
  
  def reset_word
    @word_pieces = nil
    @word_effects.clear
  end
  
  def use_item(type)
    if type == :waveTransmitter
      @action = :wave_transmitter_source
    elsif type == :dynamite
      @action = :dynamite
    else
      @time_stopped = Const::STOP_TIME_DURATION
      @effects << HourglassEffect.new
      @effects << TimerEffect.new
      consume_item(:hourglass)
    end
    @selected_piece = nil
    @cursor_position.y -= 480
  end
  
  def consume_item(type)
    @items[type] -= 1
    if @items[type] == 0
      index = @items.keys.index(type)
      ((index+1)...@items.size).each do |i|
        @item_buttons[i].set_position(@item_buttons[i].x, @item_buttons[i].y - 28)
      end
      @item_buttons.delete_at(index)
      @items.delete(type)
    end
  end
  
  def die
    set_state(:dead)
    @timer = 0
  end
  
  def finish
    set_state(:finished)
    @timer = 0
    
    @score[:time] = @time_left * 5
    @score[:items] = @items.values.sum * 200
    @score[:total] = @time_left > 0 ? @score[:default] + @score[:time] + @score[:items] : 0
    
    player_score = ConnecMan.player.scores[@num - 1]
    if !player_score || @score[:total] > player_score
      ConnecMan.player.scores[@num - 1] = @score[:total]
      @new_high_score = true
    end
    
    if @num == ConnecMan.player.last_stage && !ConnecMan::SYMBOLS_PER_LEVEL[@num - 1].empty?
      ConnecMan::SYMBOLS_PER_LEVEL[@num - 1].each do |s|
        ConnecMan.player.learned_symbols[s] = true
      end
      @new_letters = true
    end
  end
  
  def update
    clicked = ConnecMan.mouse_control && Mouse.button_pressed?(:left) || !ConnecMan.mouse_control && (KB.key_pressed?(Gosu::KB_SPACE) || KB.key_pressed?(Gosu::KB_RETURN))
    
    if @state == :starting
      @timer += 1
      if @timer == 120
        if !@message_shown && @num == ConnecMan.player.last_stage && !ConnecMan.player.completed && File.exist?("#{Res.prefix}img/messages/#{@num}.png")
          set_state(:start_message)
          @message_shown = true
        else
          set_state(:main)
        end
        @timer = 0
        return
      end
    elsif @state == :start_message
      @timer += 1 if @timer < 120
      if @timer == 120 && clicked
        set_state(:main)
        @timer = 0
        return
      end
    elsif @state == :options
      Options.update
      super
      return
    elsif @state == :dead
      if @timer == 59
        Gosu::Song.current_song.stop
        ConnecMan.play_sound('11')
      end
      @timer += 1 if @timer < 60
    elsif @state == :finished
      @timer += 1 if @timer < 180
      if @timer == 60
        Gosu::Song.current_song.stop
        ConnecMan.play_sound('10')
      elsif @timer == 180 && clicked
        if @num == Const::LAST_STAGE
          if ConnecMan.player.completed
            ConnecMan.back_to_world_map
          else
            ConnecMan.play_sound('4')
            @final_pieces = [
              GameObject.new(-64, -64, 64, 64, :main_crystal0),
              GameObject.new(Const::SCR_W, -64, 64, 64, :main_crystal1),
              GameObject.new(-64, 480, 64, 64, :main_crystal2),
              GameObject.new(Const::SCR_W, 480, 64, 64, :main_crystal3),
            ]
            @final_piece_positions = [
              Vector.new(319, 161), Vector.new(415, 161), Vector.new(319, 257), Vector.new(415, 257)
            ]
            set_state(:final_effect)
            @timer = 0
          end
        elsif @num == ConnecMan.player.last_stage
          if @num % 6 == 0
            ConnecMan.play_sound('12')
            set_state(:finish_message)
            @timer = 0
          else
            ConnecMan.next_level
          end
        else
          ConnecMan.back_to_world_map
        end
      end
    elsif @state == :finish_message
      @timer += 1 if @timer < 180
      if @timer == 180 && clicked
        ConnecMan.next_world
      end
    elsif @state == :final_effect
      if @timer < 4
        @final_pieces[@timer].move_free(@final_piece_positions[@timer], 3)
        if @final_pieces[@timer].speed.x == 0
          @timer += 1
          if @timer == 4
            @effects << Effect.new(302, 144, :fx_final, 3, 1, 10, [0, 1, 2, 1], 1000)
          end
        end
      else
        @timer += 1
        if @timer == 304
          ConnecMan.show_game_end
        end
      end
    end

    if @state == :main || @state == :dead || @state == :finished || @state == :final_effect
      @effects.reverse_each do |e|
        e.update
        @effects.delete(e) if e.dead
      end
      @score_effects.reverse_each do |e|
        e[:lifetime] -= 1
        @score_effects.delete(e) if e[:lifetime] == 0
      end
    end
    
    if ConnecMan.mouse_control
      @buttons[@state].each(&:update) if @buttons[@state]
      @item_buttons.each(&:update)
    elsif @state != :main || @cursor_position.y >= 480
      super
      clicked = false if @state == :main
    end
    
    return unless @state == :main
    
    if ConnecMan.shortcut_keys
      if KB.key_pressed?(Gosu::KB_P)
        set_state(:paused)
      elsif KB.key_pressed?(Gosu::KB_R)
        @confirm_exit = false
        set_state(:confirm)
      elsif KB.key_pressed?(Gosu::KB_C)
        ConnecMan.mouse_control = !ConnecMan.mouse_control
      elsif KB.key_pressed?(Gosu::KB_W) && @items[:waveTransmitter]
        use_item(:waveTransmitter)
      elsif KB.key_pressed?(Gosu::KB_D) && @items[:dynamite]
        use_item(:dynamite)
      elsif KB.key_pressed?(Gosu::KB_H) && @items[:hourglass]
        use_item(:hourglass)
      end
    end
    
    if @time_stopped
      @time_stopped -= 1
      if @time_stopped == 0
        @time_stopped = nil
      end
    else
      if @time_left > 0
        @timer += 1
        if @timer == 60
          @time_left -= 1
          @timer = 0
        end
      end

      @pieces.each do |_, row|
        row.each do |_, cell|
          cell.update(self) if cell
        end if row
      end
    end
    
    if ConnecMan.mouse_control
      row = (Mouse.y - @margin.y) / Const::TILE_SIZE
      col = (Mouse.x - @margin.x) / Const::TILE_SIZE
    else
      row = (@cursor_position.y - @margin.y) / Const::TILE_SIZE
      col = (@cursor_position.x - @margin.x) / Const::TILE_SIZE
      if KB.key_pressed?(Gosu::KB_TAB)
        if @cursor_position.y < 480
          @cursor_position.y += 480
          @cursor_points = []
          menu_btn = @buttons[:main][0]
          point = {x: menu_btn.x + menu_btn.w / 2, y: menu_btn.y + menu_btn.h / 2, button: menu_btn}
          point[:rt] = point[:lf] = 1 unless @item_buttons.empty?
          @cursor_points << point
          @item_buttons.each_with_index do |b, i|
            @cursor_points << {
              x: b.x + b.w / 2,
              y: b.y + b.h / 2,
              button: b,
              up: i > 0 ? i : @item_buttons.size,
              dn: i < @item_buttons.size - 1 ? i + 2 : 1,
              lf: 0, rt: 0
            }
          end
          @cursor_point_index = -1
          set_cursor_point(0)
        else
          reset_current_button
          @cursor_position.y -= 480
        end
        return
      elsif @cursor_position.y < 480
        if row > 0 && (KB.key_pressed?(Gosu::KB_UP) || KB.key_held?(Gosu::KB_UP))
          @cursor_position.y -= Const::TILE_SIZE
          row -= 1
        elsif col < @cols - 1 && (KB.key_pressed?(Gosu::KB_RIGHT) || KB.key_held?(Gosu::KB_RIGHT))
          @cursor_position.x += Const::TILE_SIZE
          col += 1
        elsif row < @rows - 1 && (KB.key_pressed?(Gosu::KB_DOWN) || KB.key_held?(Gosu::KB_DOWN))
          @cursor_position.y += Const::TILE_SIZE
          row += 1
        elsif col > 0 && (KB.key_pressed?(Gosu::KB_LEFT) || KB.key_held?(Gosu::KB_LEFT))
          @cursor_position.x -= Const::TILE_SIZE
          col -= 1
        end
      end
    end
    
    piece = row >= 0 && col >= 0 && @pieces[row] && @pieces[row][col]
    over_selectable_piece = piece && piece.selectable
    
    if over_selectable_piece
      @hovered_piece = @pieces[row][col]
    else
      @hovered_piece = nil
    end
    
    return if !ConnecMan.mouse_control && @cursor_position.y >= 480 || !clicked
    
    if @action == :dynamite && row >= 0 && col >= 0 && row < @rows && col < @cols
      unless piece.is_a?(Rock) && !piece.fragile || piece.is_a?(Piece) && piece.type == 9
        @pieces[row][col] = nil
        @piece_count -= 1
        update_pairs(piece.is_a?(Piece) ? piece : nil, nil, false, false)
      end
      @effects << Effect.new(col * Const::TILE_SIZE + @margin.x - 9, row * Const::TILE_SIZE + @margin.y - 9, :fx_explosion, 2, 2, 7, [0, 1, 2, 3, 2, 1, 0], nil, '9')
      consume_item(:dynamite)
      @hovered_piece = nil
      @action = :default
    elsif over_selectable_piece
      if @action == :default
        if @selected_piece
          if piece == @selected_piece
            @selected_piece = nil
            reset_word
          elsif @word_pieces
            if piece.type == 9 && piece.symbol == @word[@word_pieces.size]
              path = find_path(piece, @selected_piece)
              if path
                if @word_pieces.size == @word.size - 1
                  add_path_effects(path, false, true)
                  @word_effects.each do |eff|
                    img = eff.img_id == :fx_specialWays ? :fx_ways : :fx_wayExtremity
                    @effects << CEffect.new(eff.x, eff.y, img, img == :fx_ways ? 3 : nil, img == :fx_ways ? 2 : nil, 0, [eff.img_index], 60, 0xff99ffff)
                  end
                  @word_effects.clear
                  @word_pieces << piece
                  @word_pieces.each do |p|
                    add_piece_effect(p)
                    connect(p)
                  end
                  ConnecMan.play_sound('5')
                  @selected_piece = @hovered_piece = nil
                  finish
                else
                  add_path_effects(path, true)
                  @selected_piece = piece
                  @word_pieces << piece
                end
              else
                reset_word
                select(piece)
              end
            else
              reset_word
              select(piece)
            end
          elsif piece.match?(@selected_piece)
            path = find_path(piece, @selected_piece)
            if path
              add_path_effects(path)
              add_piece_effect(piece)
              add_piece_effect(@selected_piece)
              strong1 = piece.type >= 3 && piece.type <= 5
              strong2 = @selected_piece.type >= 3 && @selected_piece.type <= 5
              connect(piece)
              connect(@selected_piece)
              update_pairs(piece, @selected_piece, strong1, strong2)
              ConnecMan.play_sound('5')
              @selected_piece = @hovered_piece = nil
            else
              select(piece)
            end
          else
            select(piece)
          end
        else
          select(piece)
        end
      elsif @action == :wave_transmitter_source
        if piece.type != 9
          @selected_piece = piece
          @action = :wave_transmitter_dest
        end
      elsif @action == :wave_transmitter_dest
        if piece != @selected_piece && piece.match?(@selected_piece)
          add_piece_effect(piece)
          add_piece_effect(@selected_piece)
          add_wave_effects(@selected_piece, piece)
          strong1 = piece.type >= 3 && piece.type <= 5
          strong2 = @selected_piece.type >= 3 && @selected_piece.type <= 5
          connect(piece)
          connect(@selected_piece)
          consume_item(:waveTransmitter)
          update_pairs(piece, @selected_piece, strong1, strong2)
          @selected_piece = nil
          @action = :default
        end
      end
    elsif @selected_piece &&
          (@selected_piece.movable[:up] && @selected_piece.col == col && @selected_piece.row == row + 1 ||
           @selected_piece.movable[:rt] && @selected_piece.row == row && @selected_piece.col == col - 1 ||
           @selected_piece.movable[:dn] && @selected_piece.col == col && @selected_piece.row == row - 1 ||
           @selected_piece.movable[:lf] && @selected_piece.row == row && @selected_piece.col == col + 1)
      @pieces[row][col] = @selected_piece
      @pieces[@selected_piece.row][@selected_piece.col] = nil
      @selected_piece.move(row, col)
    else
      reset_word
      @selected_piece = nil
      @action = :default
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

    x1 = @margin.x - 2
    x2 = @margin.x + @cols * Const::TILE_SIZE + 2
    y1 = @margin.y - 2
    y2 = @margin.y + @rows * Const::TILE_SIZE + 2
    c2 = 0x00ffffff & @frame_color
    if @rows < Const::MAX_ROWS
      offset = @cols < Const::MAX_COLS ? 15 : 0
      G.window.draw_quad(x1, y1, @frame_color,
                         x2, y1, @frame_color,
                         x1 - offset, y1 - 15, c2,
                         x2 + offset, y1 - 15, c2, 0)
      G.window.draw_quad(x1, y2, @frame_color,
                         x2, y2, @frame_color,
                         x1 - offset, y2 + 15, c2,
                         x2 + offset, y2 + 15, c2, 0)
    end
    if @cols < Const::MAX_COLS
      offset = @rows < Const::MAX_ROWS ? 15 : 0
      G.window.draw_quad(x1, y1, @frame_color,
                         x1, y2, @frame_color,
                         x1 - 15, y1 - offset, c2,
                         x1 - 15, y2 + offset, c2, 0)
      G.window.draw_quad(x2, y1, @frame_color,
                         x2, y2, @frame_color,
                         x2 + 15, y1 - offset, c2,
                         x2 + 15, y2 + offset, c2, 0)
    end
    
    @panel.draw(0, 480, 0)
    @effects.each(&:draw)
    @word_effects.each(&:draw)
    @score_effects.each do |e|
      @font.draw_text_rel(e[:text], e[:x], e[:y] - 20 + e[:lifetime] / 3, 0, 0.5, 0.5, 0.5, 0.5, e[:color])
    end
    color = @time_left > 0 ? WHITE : 0xffff0000
    @font.draw_text(ConnecMan.text(:score) + (@time_left > 0 ? @score[:default].to_s : '0'), 50, 502, 0, 0.5, 0.5, color)
    @font.draw_text(ConnecMan.text(:time) + @time_left.to_s, 50, 558, 0, 0.5, 0.5, color)
    @items.each_with_index do |(k, v), i|
      y = 500 + i * 28
      Res.img("icon_#{k}").draw(660, y, 0)
      @font.draw_text(v.to_s, 690, y, 0, 0.5, 0.5, WHITE)
      if @state == :main && ConnecMan.mouse_control && Mouse.over?(660, y, 25, 25)
        Res.img(:main_ItemHighlight).draw(658, y - 2, 0)
      end
    end
    
    if @state == :starting
      @font.draw_text_rel(ConnecMan.text(:level).upcase + @num.to_s, 400, 240, 0, 0.5, 0.5, 1, 1, YELLOW)
    elsif @state == :start_message
      draw_overlay
      board_y = (480 - @board.height) / 2
      @board.draw((Const::SCR_W - @board.width) / 2, board_y, 0)
      ConnecMan.default_font.draw_text_rel(ConnecMan.text("message_title_#{@num}"), Const::SCR_W / 2, board_y + 20, 0, 0.5, 0, 1, 1, YELLOW)
      ConnecMan.text_helper.write_breaking(ConnecMan.text("message_#{@num}"), 120, 120, 560, :justified, 0xffffff)
      img = Res.img("messages_#{@num}")
      img.draw((Const::SCR_W - img.width) / 2, (480 - img.height) / 2 + 70, 0)
      ConnecMan.default_font.draw_text_rel(ConnecMan.text("#{ConnecMan.mouse_control ? 'click' : 'press'}_to_continue"), Const::SCR_W / 2, 400, 0, 0.5, 0, 0.75, 0.75, WHITE) if @timer == 120
    elsif @state == :options
      draw_buttons(:main)
      draw_overlay
      Options.draw
    elsif @state == :paused || @state == :confirm
      draw_buttons(:main)
      draw_overlay
      @menu.draw((Const::SCR_W - @menu.width) / 2, (Const::SCR_H - @menu.height) / 2, 0)
      @font.draw_text_rel(ConnecMan.text(@state), Const::SCR_W / 2, (Const::SCR_H - @menu.height) / 2 + 25, 0, 0.5, 0, 0.5, 0.5, BLACK)
    elsif @state == :dead && @timer >= 60
      @font.draw_text_rel(ConnecMan.text(:no_moves_left), 400, 240, 0, 0.5, 0.5, 0.9, 0.9, 0xffff0000)
    elsif @state == :finished && @timer >= 60
      @font.draw_text_rel(ConnecMan.text(:level_completed), 400, 160, 0, 0.5, 0, 1, 1, LIGHT_BLUE)
      @font.draw_text_rel(ConnecMan.text(:time_bonus) + @score[:time].to_s, 400, 210, 0, 0.5, 0, 0.5, 0.5, LIGHT_BLUE) if @time_left > 0
      @font.draw_text_rel(ConnecMan.text(:items_bonus) + @score[:items].to_s, 400, 235, 0, 0.5, 0, 0.5, 0.5, LIGHT_BLUE) if @time_left > 0
      @font.draw_text_rel(ConnecMan.text(:total) + @score[:total].to_s + (@time_left > 0 ? '' : ConnecMan.text(:time_up)), 400, 260, 0, 0.5, 0, 0.5, 0.5, LIGHT_BLUE)
      @font.draw_text_rel(ConnecMan.text(:new_high_score), 400, 285, 0, 0.5, 0, 0.5, 0.5, YELLOW) if @new_high_score
      @font.draw_text_rel(ConnecMan.text(:new_letters), 400, 310, 0, 0.5, 0, 0.5, 0.5, YELLOW) if @new_letters
      @font.draw_text_rel(ConnecMan.text("#{ConnecMan.mouse_control ? 'click' : 'press'}_to_continue").upcase, 400, 350, 0, 0.5, 0, 0.4, 0.4, WHITE) if @timer == 180
    elsif @state == :finish_message
      draw_overlay
      board_y = (480 - @board.height) / 2
      @board.draw((Const::SCR_W - @board.width) / 2, board_y, 0)
      num = (@num - 1) / 6
      ConnecMan.default_font.draw_text_rel(ConnecMan.text("world_#{num + 1}") + ConnecMan.text(:world_completed), Const::SCR_W / 2, board_y + 20, 0, 0.5, 0, 1, 1, WHITE)
      msg = ConnecMan.text(:bonus_message).sub('$', NISLED_WORDS[num]).gsub('$', ConnecMan.text("crystal_#{num}"))
      ConnecMan.text_helper.write_breaking(msg, 120, 120, 560, :justified, 0xffffff, 255, 0, 0.75, 0.75)
      img = Res.img("messages_bonus_#{num}")
      img.draw((Const::SCR_W - img.width) / 2, (480 - img.height) / 2 + 20, 0)
      ConnecMan.default_font.draw_text_rel(ConnecMan.text("#{ConnecMan.mouse_control ? 'click' : 'press'}_to_continue"), Const::SCR_W / 2, 400, 0, 0.5, 0, 0.75, 0.75, WHITE) if @timer == 180
    elsif @state == :final_effect
      @final_pieces.each(&:draw) if @timer < 4
    end
    draw_buttons(@state) if @buttons[@state] && (@state != :dead || @timer >= 60)

    cursor = if @state == :main
               if @action == :wave_transmitter_source
                 Res.img(:cursor_WaveTransmitter)
               elsif @action == :wave_transmitter_dest
                 Res.img(:cursor_WaveReceptor)
               elsif @action == :dynamite
                 Res.img(:cursor_Dynamite)
               else
                 Res.img(:cursor_Default)
               end
             else
               Res.img(:cursor_Default)
             end
    if ConnecMan.mouse_control
      cursor.draw(Mouse.x - cursor.width / 2, Mouse.y, 10)
    elsif @state == :main && @cursor_position.y < 480
      cursor.draw(@cursor_position.x - cursor.width / 2, @cursor_position.y, 0)
    else
      super
    end
  end
end
