class Player
  attr_reader :name, :last_world, :last_stage, :scores

  def initialize(name = '-', last_world = 1, last_stage = 1, scores = [])
    @name = name
    @last_world = last_world
    @last_stage = last_stage
    @scores = scores

    # TODO learned symbols
  end
end
