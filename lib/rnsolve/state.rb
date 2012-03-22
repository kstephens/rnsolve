require 'rnsolve'

module RNSolve
  class State
    def initialize
      @slots = { }
    end

    def clear!
      @slots.clear
      self
    end

    def value? node
      ! ! @slots[node.object_id]
    end

    def value! node, value
      s = slot(node)
      s[0] = value
      self
    end
    alias :set! :value!

    def value node
      (
        @slots[node.object_id] ||=
        [
          node.value!(self),
          node,
        ]
        ).first
    end

    def slot node
      @slots[node.object_id] ||= [ nil, node ]
    end

  end

  class Propagator
    def initialize
      @state = State.new
      @visited = { }
    end

    def set! node, value
      @state.set! node, value
    end

    def value? node
      @state.value? node
    end

    def propagate! node, value = nil
      return self if @visited[node.object_id]
      @visited[node.object_id] ||= node
      @state.set! node, value unless value.nil?
      node.propagate!(self)
      self
    end

    def value node
      if value? node
      end
    end

  end

end


