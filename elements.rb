class BoardElement
  attr_reader :row, :col, :selectable
  
  def initialize(row, col)
    @row = row
    @col = col
  end
  
  def update(stage); end
  
  def draw(margin)
    @img.draw(@col * Const::TILE_SIZE + margin.x, @row * Const::TILE_SIZE + margin.y, 0)
  end
end

class Rock < BoardElement
  attr_reader :fragile
  
  def initialize(row, col, fragile)
    super(row, col)
    @fragile = fragile
    @img = Res.imgs(:board_blocks, 3, 1)[fragile ? 2 : 0]
  end
end

class IceBlock < BoardElement
  def initialize(row, col, item)
    super(row, col)
    @item = item
    @img = Res.imgs(:board_blocks, 3, 1)[1]
  end
  
  def item
    case @item
    when 0 then :waveTransmitter
    when 1 then :hourglass
    when 2 then :dynamite
    else        nil
    end
  end
  
  def draw(margin)
    Res.img("icon_#{item}").draw(col * Const::TILE_SIZE + margin.x + 4, row * Const::TILE_SIZE + margin.y + 4, 0) if @item
    super(margin)
  end
end

class Piece < BoardElement
  attr_reader :type, :symbol, :movable, :score
  
  def initialize(row, col, type, symbol)
    super(row, col)
    @type = type
    @symbol = symbol
    
    @img = Res.imgs(:board_pieces, 5, 2)[type]
    @sym_img = Res.imgs(type == 9 ? :symbols_black : :symbols_white, 8, 4)[symbol]
    @movable = {}
    @selectable = true
    @score = case type
             when 0..5 then 5
             when 6    then 400
             when 7    then 200
             when 8    then 100
             else           50
             end
    @min_score = case type
                 when 6 then 40
                 when 7 then 20
                 when 8 then 10
                 end
    @timer = 0
  end
  
  def set_movable(dir)
    @movable[dir] = true
    @arrows = Res.imgs(:board_arrows, 2, 2) if @arrows.nil?
  end
  
  def match?(other)
    @symbol == other.symbol && (@type == other.type || @type <= 5 && other.type <= 5 && (@type - other.type).abs == 3)
  end
  
  def change_type(type)
    @type = type
    @img = Res.imgs(:board_pieces, 5, 2)[type]
  end
  
  def move(row, col)
    @row = row
    @col = col
  end
  
  def update(stage)
    return unless @type >= 6 && @type <= 8
    return unless @score > @min_score
    @timer += 1
    if @timer == 600
      @score -= @min_score / 2
      stage.add_score_effect(@row, @col, @score, true)
      @timer = 0
    end
  end
  
  def draw(margin)
    x = @col * Const::TILE_SIZE + margin.x
    y = @row * Const::TILE_SIZE + margin.y
    @img.draw(x, y, 0)
    @sym_img.draw(x, y, 0)
    @arrows[0].draw(x, y, 0) if @movable[:up]
    @arrows[1].draw(x, y, 0) if @movable[:rt]
    @arrows[2].draw(x, y, 0) if @movable[:dn]
    @arrows[3].draw(x, y, 0) if @movable[:lf]
  end
end
