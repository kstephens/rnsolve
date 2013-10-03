require 'pp'
require 'rational'

module RNSolve
  class Node
    module NumericNode
      def _constant x
        NumericConstant[x]
      end

      def integer?;  false; end
      def rational?; false; end
      def real?;     false; end
      def simplify;    self; end
      def simplified?; true; end
      def simplified!; self; end
      def add_dependents!; end

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
      def integer?;  Integer === value; end
      def rational?; Rational === value; end
      def real?;     Float === value; end
    end

    class NumericVariable < Variable
      include NumericNode
    end

    class NumericOperation < Operation
      include NumericNode
      def self.[] *args
        op = new
        args.map!{|x| op._coerce(x)}
        op = new(*args)
      end

      def simplify
        $stderr.puts "  # #{self.class}.simplify(#{@a.inspect}, #{@b.inspect})"
        @a = @a.simplify if @a
        @b = @b.simplify if @b
        # $stderr.puts "  op.subnodes = #{op.subnodes.inspect}"
        if subnodes.all? { | n | NumericConstant === n }
          s = State.new
          v = value!(s)
          return NumericConstant[v]
        end
        s = _simplify
        if s != self
          s = s.simplify
        end
        s.simplified!
      end
      def simplified?; @simplified; end
      def simplified!; @simplified = true; self; end

      def initialize a = nil, b = nil
        $stderr.puts "  # #{self.class}.new(#{a.inspect}, #{b.inspect})"
        @a = a; @b = b
      end

      def add_dependents!
        @a.add_dependent!(self) if @a
        @b.add_dependent!(self) if @b
        @a.add_dependents! if @a
        @b.add_dependents! if @b
      end

      def _simplify
        self
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
        def _simplify
          if Variable === @a and not Variable === @b
            return Add[@b, @a]
          end
          if Mul === @a and Mul === @b and Variable === (v = @a.subnodes[1]) and v == @b.subnodes[1]
            return Mul[Add[@a.subnodes[0], @b.subnodes[0]], v]
          end
          super
        end
        def inverse! s, dst, value, other = nil
          if other == nil # value = dst + dst => dst = value / 2
            value / 2
          else
            value - other
          end
        end
      end # class

      class Sub
        def _simplify
          if Variable === @a and not Variable === @b
            return Add[Neg[@b], @a]
          end
          super
        end
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
        def _simplify
          if Variable === @a and not Variable === @b
            return Mul[@b, @a]
          end
          super
        end

        def inverse! s, dst, value, other = nil
          if other == nil # value = dst * dst => dst = sqrt(value)
            sqrt(value)
          else
            value / other
          end
        end
      end # class

      class Div
        def _simplify
          # x / 123 = x * (1/123)
          if Variable === @a and Constant === @b
            if @b.integer?
              b = _constant(1 / @b.value.to_r)
            else
              b = _constant(1 / @b.value)
            end
            return Mul[b, @a]
          end
          super
        end

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

