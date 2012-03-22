require 'rnsolve'

module RNSolve
  class State
    attr_accessor :debug

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
          (v = node.value!(self)
            $stderr.puts "  #{node} value => #{v}" if @debug
            v),
          node,
        ]
        ).first
    end

    def slot node
      @slots[node.object_id] ||= [ nil, node ]
    end

  end
end


