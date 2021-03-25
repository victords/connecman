class Event
  def initialize
    @listeners = []
  end

  def +(listener)
    @listeners << listener
    self
  end

  def invoke(*args)
    @listeners.each do |l|
      l.call(*args)
    end
  end
end
