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
            $stderr.puts "  #{node} value => #{v}" if @debug && ! Node::Constant === node
            v),
          node,
        ]
        ).first
    end

    def slot node
      @slots[node.object_id] ||= [ nil, node ]
    end

    def to_h
      h = { }
      @slots.each do | node, slot |
        h[slot[1]] = slot.first
      end
      h
    end

    def node_to_s x
      case x
      when Node::Variable
        value?(x) ? "#{x} = #{value(x)}" : x.to_s
      when Node
        value?(x) ? value(x).to_s : x.node_to_s(self)
      else
        x.to_s
      end
    end
  end
end


