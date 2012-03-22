require 'pp'

module RNSolve
  class Node
    def value! state
      raise "Subclass Implementation"
    end

    def _coerce x
      case x
      when nil, Node
        x
      else
        _constant(x)
      end
    end

    def _constant x
      Constant.new(x)
    end

    class Constant < self
      def initialize value
        @value = value
      end
      def value! state
        @value
      end
    end

    class Variable < self
      def initialize name
        @name = name
      end
      def value! state
        raise "#{self.inspect} is unbound"
      end
    end

    class Operation < self
    end

  end
end

