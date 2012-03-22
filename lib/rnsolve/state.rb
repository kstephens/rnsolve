module RNSolve
  class State
    def initialize
      @value = { }
    end

    def clear!
      @value.clear
      self
    end

    def value node
      (
        @value[node.object_id] ||=
        [
          node.value!(self),
          node,
        ]
        ).first
    end
  end
end


