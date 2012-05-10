require 'pp'

module RNSolve
  class Node
    EMPTY_Array = [ ].freeze

    def value! state
      raise "Subclass Implementation"
    end

    def dependents
      @dependents ? @dependents.values : EMPTY_Array
    end

    def add_dependent! node
      (@dependents ||= { })[node.object_id] = node
      self
    end

    def subnodes
      EMPTY_Array
    end

    def solve! dst, value
      $stderr.puts "  #{self}.solve! #{dst}, #{value}"
      raise "unimplemented"
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

    def node_to_s s
      to_s
    end

    class Constant < self
      class << self
        alias :[] :new
      end
      def initialize value
        @value = value
      end
      def value! state
        @value
      end
      def computable? state
        true
      end
      def to_s
        @to_s ||=
          "#{@value}".freeze
      end
      def inspect
        "#{self.class.name}[#{@value.inspect}]"
      end
    end

    class Variable < self
      def initialize name
        @name = name
      end
      def value! state
        raise Error::UnknownValue, "#{self.inspect} is unbound"
      end
      def computable? state
        state.value?(self)
      end
      def to_s
        @to_s ||=
          "#{@name}".freeze
      end

    end

    class Operation < self
    end

  end
end

