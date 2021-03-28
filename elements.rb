class BoardElement
  attr_reader :row, :col
  
  def initialize(row, col)
    @row = row
    @col = col
  end
  
  def draw(margin)
    @img.draw(@col * Const::TILE_SIZE + margin.x, @row * Const::TILE_SIZE + margin.y, 0)
    @sym_img.draw(@col * Const::TILE_SIZE + margin.x, @row * Const::TILE_SIZE + margin.y, 0) if @sym_img
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
end

class Piece < BoardElement
  attr_reader :type, :symbol, :movable
  
  def initialize(row, col, type, symbol)
    super(row, col)
    @type = type
    @symbol = symbol
    
    @img = Res.imgs(:board_pieces, 5, 2)[type]
    @sym_img = Res.imgs(type == 9 ? :symbols_black : :symbols_white, 8, 4)[symbol]
    @movable = {}
  end
  
  def set_movable(dir)
    @movable[dir] = true
    @arrows = Res.imgs(:board_arrows, 2, 2) if @arrows.nil?
  end
  
  def draw(margin)
    super(margin)
    @arrows[0].draw(@col * Const::TILE_SIZE + margin.x, @row * Const::TILE_SIZE + margin.y, 0) if @movable[:up]
    @arrows[1].draw(@col * Const::TILE_SIZE + margin.x, @row * Const::TILE_SIZE + margin.y, 0) if @movable[:rt]
    @arrows[2].draw(@col * Const::TILE_SIZE + margin.x, @row * Const::TILE_SIZE + margin.y, 0) if @movable[:dn]
    @arrows[3].draw(@col * Const::TILE_SIZE + margin.x, @row * Const::TILE_SIZE + margin.y, 0) if @movable[:lf]
  end
end
