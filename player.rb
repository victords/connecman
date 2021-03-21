class Player
  attr_reader :name, :completed, :last_stage, :last_world, :scores

  def initialize(name = '-', completed = false, last_stage = 1, scores = [])
    @name = name
    @completed = completed
    @last_stage = last_stage
    @last_world = (last_stage - 1) / 6 + 1
    @scores = scores

    # TODO learned symbols
  end
end
