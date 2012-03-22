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
        $stderr.puts "  # #{self.class}.new(#{a.inspect}, #{b.inspect}) : #{self.class.ancestors.inspect}"
        @a = _coerce(a)
        @b = _coerce(b) if b
      end
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
        class #{cls} < NumericOperation
          def value! state
            state.value(@a) #{sel} state.value(@b)
          end
        end
        MAP[#{op.inspect}] = { :cls => #{cls}, :op => #{op.inspect}, :sel => #{sel.inspect} }
END
      end * "\n"
      $stderr.puts expr
      eval(expr)
      # pp MAP

      class Add
        def propagate! p
          case
          when p.value?(node)
            v = p.value(node)
            case
            when ! p.value?(@a) && p.value?(@b)
              p.propagate!(@a, v - p.value(@b))
            when ! p.value?(@b) && p.value?(@a)
              p.propagate!(@b, v - p.value(@a))
            else
              raise
            end
          else
            raise
          end # case 
        end # def
      end # class
    end
  end
end

