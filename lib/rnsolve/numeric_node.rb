require 'pp'

module RNSolve
  class Node
    module NumericNode
      def _constant x
        NumericConstant[x]
      end

      def method_missing sel, *args, &blk
        # $stderr.puts "  # #{sel}, #{self.inspect}, #{args.inspect}"
        if cls = NumericOperation::MAP[sel] and cls = cls[:cls]
          # $stderr.puts "  #   => #{cls}"
          # $stderr.puts "   #{caller * "\n  "}"
          cls[self, *args]
        else
          super
        end
      end

      # Integer-preserving sqrt().
      def sqrt x
        return x if x.zero?
        v = Math.sqrt(x)
        if Integer === x and (vi = v.to_i) and vi * vi == x
          v = vi
        end
        NumericSet[ - v, v ]
      end
    end

    class NumericSet < self
      include NumericNode
      class << self
        alias :[] :new
      end
      def initialize *values
        super()
        @values = values
        @values.sort!
        @values.freeze
      end
      def values
        @values
      end
      def == x
        self.class === x and (object_id == x.object_id or values == x.values)
      end
      def <=> x
        values <=> x.values
      end
      def inspect
        "#{self.class.name}[#{@values * ", "}]"
      end
      alias :to_s :inspect
    end

    class NumericConstant < Constant
      include NumericNode
    end

    class NumericVariable < Variable
      include NumericNode
    end

    class NumericOperation < Operation
      include NumericNode
      def self.[] *args
        op = new(*args)
        # $stderr.puts "  op.subnodes = #{op.subnodes.inspect}"
        if op.subnodes.all? { | n | NumericConstant === n }
          s = State.new
          v = op.value!(s)
          op = NumericConstant[v]
        end
        op
      end

      def initialize a, b = nil
        # $stderr.puts "  # #{self.class}.new(#{a.inspect}, #{b.inspect}) : #{self.class.ancestors.inspect}"
        @a = _coerce(a).add_dependent!(self)
        @b = _coerce(b).add_dependent!(self) if b
      end

      def subnodes
        @subnodes ||=
          (@b ? [ @a, @b ] : [ @a ]).freeze
      end

      def computable? s
        s.computable?(@a) && (! @b || s.computable?(@b))
      end

      def to_s
        @to_s ||=
          "(#{@a} #{op_name} #{@b})".freeze
      end

      def node_to_s s
        "(#{s.node_to_s(@a)} #{op_name} #{s.node_to_s(@b)})"
      end

      MAP = { }
      expr =
        [
        [ :Add, :+ ],
        [ :Sub, :- ],
        [ :Mul, :* ],
        [ :Div, :/ ],
        [ :Neg, :-@, :- ],
      ].map do | ( cls, op, sel ) |
        sel ||= op
        <<"END"
        class #{cls} < NumericOperation
          def op_name; #{op.inspect}; end
          def value! state
            state.value(@a) #{sel} state.value(@b)
          end
        end
        MAP[#{op.inspect}] = { :cls => #{cls}, :op => #{op.inspect}, :sel => #{sel.inspect} }
END
      end * "\n"
      # $stderr.puts expr
      eval(expr)
      # pp MAP

      class Neg
        def value! state
          - state.value(@a)
        end
        def inverse! s, dst, value, other = nil
          - value
        end
      end
      class Add
        def inverse! s, dst, value, other = nil
          if other == nil # value = dst + dst => dst = value / 2
            value / 2
          else
            value - other
          end
        end
      end # class
      class Sub
        def inverse! s, dst, value, other = nil
          if other == nil # value = dst - dst   =>   dst = ANY?
            not_implemented
          else
            # value = dst - other  =>  dst = value + other
            value + other
          end
        end
      end # class
      class Mul
        def inverse! s, dst, value, other = nil
          if other == nil # value = dst * dst => dst = sqrt(value)
            sqrt(value)
          else
            value / other
          end
        end
      end # class
      class Div
        def inverse! s, dst, value, other = nil
          if other == nil # value = dst / dst  =>  dst != 0
            not_implemented
          else
            # value = dst / other
            #  =>
            # value * other = dst, where other != 0
            value * other
          end
        end
      end # class
    end
  end
end

