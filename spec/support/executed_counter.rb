class ExecutedCounter
  def initialize(block)
    @block = block
    @called = 0
  end

  def to_proc
    lambda do |*args| 
      @called += 1 
      @block[*args] 
    end
  end

  def called?
    @called > 0
  end
end
