require 'pp'

module RNSolve
  class Node
    module NumericNode
      def _constant x
        NumericConstant.new(x)
      end

      def method_missing sel, *args, &blk
        # $stderr.puts "  # #{sel}, #{self.inspect}, #{args.inspect}"
        if cls = NumericOperation::MAP[sel] and cls = cls[:cls]
          # $stderr.puts "  #   => #{cls}"
          # $stderr.puts "   #{caller * "\n  "}"
          cls.new(self, *args)
        else
          super
        end
      end
    end

    class NumericConstant < Constant
      include NumericNode
    end

    class NumericVariable < Variable
      include NumericNode
    end

    class NumericOperation < Operation
      include NumericNode
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

      MAP = { }
      expr =
        [
        [ :Add, :+ ],
        [ :Sub, :- ],
        [ :Mul, :* ],
        [ :Div, :/ ],
        #  [ :Neg, :-@, :- ],
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
          not_implemented
        end
      end # class
      class Mul
        def inverse! s, dst, value, other = nil
          if other == nil # value = dst * dst => dst = sqrt(value)
            v = Math.sqrt(value)
            [ - v , v ]
          else
            value / other
          end
        end
      end # class
      class Div
        def inverse! s, dst, value, other = nil
          not_implemented
        end
      end # class
    end
  end
end

