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

    class Operation < self
    end

    module NumericNode
      def _constant x
        NumericConstant.new(x)
      end

      def method_missing sel, *args, &blk
        $stderr.puts "  # #{sel}, #{args.inspect}"
        if cls = NumericOperation::MAP[sel] and cls = cls[:cls]
          $stderr.puts "  #   => #{cls}.new(*#{args.inspect})"
          cls.new(*args)
        else
          super
        end
      end
    end

    class NumericConstant < Constant
      include NumericNode
    end

    class NumericOperation < Operation
      include NumericNode
      MAP = { }
      expr =
        [
        [ :Add, :+ ],
        [ :Sub, :- ],
        [ :Div, :/ ],
        [ :Mul, :* ],
        #  [ :Neg, :-@, :- ],
      ].map do | ( cls, op, sel ) |
        sel ||= op
        <<"END"
        class #{cls}
          def initialize a, b = nil
            @a = _coerce(a)
            @b = _coerce(b) if b
          end
          def value! state
            state.value(@a) #{sel} state.value(@b)
          end
        end
        MAP[#{op.inspect}] = { :cls => #{cls}, :op => #{op.inspect}, :sel => #{sel.inspect} }
END
      end * "\n"
        $stderr.puts expr
        eval(expr)
        pp MAP
    end

  end
end

