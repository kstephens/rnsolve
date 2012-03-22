require 'rnsolve'
require 'rnsolve/state'

module RNSolve
  class Solver
    attr_accessor :state, :debug

    def initialize
      @state = State.new
      @computing = { }
    end

    def set! node, value
      @state.set! node, value
    end

    def value? node
      @state.value? node
    end

    def try_value node
      computing = false
      if not @state.value?(node)
        if @computing[node.object_id]
          raise Error::UnknownValue
        end
        $stderr.puts "  value #{node} ..." if @debug
        computing = true
        @computing[node.object_id] = node
        # attempt to compute all subnodes of node.
        node.subnodes.each do | n |
          if not @computing[n.object_id]
            $stderr.puts "     value #{node} subnode #{n} ..." if @debug
            v = @state.value(n) rescue Error::UnknownValue
            $stderr.puts "     value #{node} subnode #{n} = #{v}" if @debug
          end
        end
        v = @state.value(node)
        $stderr.puts "  value #{node} = #{v}" if @debug
      else
        v = @state.value(node)
      end
      v
    rescue Error::UnknownValue
      if block_given?
        yield
      else
        raise
      end
    ensure
      @computing.delete(node.object_id) if computing
    end

    def value node
      try_value(node) do 
        # node cannot compute due to unknown value.
        $stderr.puts "  value #{node} UNKNOWN" if @debug
        deps = node.dependents
        deps.each do | d |
          $stderr.puts "    try #{node} dependent #{d} ..." if @debug
          v = value(d) rescue Error::UnknownValue
          $stderr.puts "    try #{node} dependent #{d} = #{v}" if @debug
        end
        if deps.find do | n |
            if @state.value?(n)
              n_v = @state.value(n)
              other_map = { }
              other = n.subnodes.select{|sn| sn != node}.map{|sn| other_map[sn] = @state.value(sn)}
              $stderr.puts "    solve #{node} using inverse of #{n_v} = #{n}, where #{other_map} " if @debug
              v = n.inverse!(@state, node, n_v, *other)
              $stderr.puts "    solve #{node} = #{v}" if @debug
              @state.set!(node, v)
            end
          end
          @state.value(node)
        else
          raise Error::Incomputable
        end
      end
    end

  end

end


