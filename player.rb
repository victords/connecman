class Player
  attr_reader :name, :completed, :last_stage, :last_world, :scores, :learned_symbols

  def initialize(name = '-', completed = false, last_stage = 1, scores = [])
    @name = name
    @completed = completed
    @last_stage = last_stage
    @last_world = (last_stage - 1) / 6 + 1
    @scores = scores
    
    @learned_symbols = {}
    (0...(last_stage-1)).each do |i|
      ConnecMan::SYMBOLS_PER_LEVEL[i].each do |s|
        @learned_symbols[s] = true
      end
    end
  end
end
