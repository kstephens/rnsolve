require 'rnsolve'
require 'rnsolve/state'

module RNSolve
  class Solver
    attr_accessor :state, :debug, :stats

    def initialize
      @state = State.new
      @computing = { }
      @stats = { }
    end

    def set! node, value
      @state.set! node, value
    end

    def value? node
      @state.value? node
    end

    def _stats! name
      v = @stats[name] || 0
      @stats[name] = v + 1
      self
    end

    def node_to_s node
      @state.node_to_s(node)
    end

    def try_value node
      _stats! :try_value
      computing = false
      if not @state.value?(node)
        if @computing[node.object_id]
          raise Error::UnknownValue
        end
        $stderr.puts "  value #{node_to_s(node)} ..." if @debug
        computing = true
        @computing[node.object_id] = node
        # attempt to compute all subnodes of node.
        node.subnodes.each do | n |
          if not @computing[n.object_id]
            _stats! :try_value_subnode
            $stderr.puts "     value #{node_to_s(node)} subnode #{node_to_s(n)} ..." if @debug
            v = @state.value(n) rescue Error::UnknownValue
            $stderr.puts "     value #{node_to_s(node)} subnode #{n} = #{v}" if @debug
          end
        end
        v = @state.value(node)
        $stderr.puts "  value #{node_to_s(node)} = #{v}" if @debug
      else
        v = @state.value(node)
      end
      v
    rescue Error::UnknownValue
      _stats! :try_value_unknown_value
      if block_given?
        yield
      else
        raise
      end
    ensure
      @computing.delete(node.object_id) if computing
    end

    def value node
      _stats! :value
      try_value(node) do
        # node cannot compute due to unknown value.
        $stderr.puts "  value #{node} UNKNOWN" if @debug
        # Try to compute a dependent value.
        deps = node.dependents
        deps.each do | dep |
          _stats! :value_try_dependent
          $stderr.puts "    try #{node_to_s(node)} dependent #{node_to_s(dep)} ..." if @debug
          v = value(dep) rescue Error::UnknownValue
          $stderr.puts "    try #{node_to_s(node)} dependent #{dep} = #{v}" if @debug
        end
        if deps.find { | dep | solve_node_using(node, dep) }
          @state.value(node)
        else
          _stats! :value_try_incomputable
          raise Error::Incomputable, "#{node}"
        end
      end
    end

    # If dependent node has a value, use it to solve for the dependent subnode's value.
    def solve_node_using node, dep
      _stats! :solve_node_using
      if @state.value?(dep)
        dep_v = @state.value(dep)
        other_map = { }
        other = dep.subnodes.select{|sn| sn != node}.map{|sn| other_map[sn] = @state.value(sn)}
        $stderr.puts "    solve #{node_to_s(node)} using inverse of #{dep_v} = #{dep}, where #{other_map} " if @debug
        v = dep.inverse!(@state, node, dep_v, *other)
        $stderr.puts "    solve #{node_to_s(node)} = #{v}" if @debug
        @state.set!(node, v)
        _stats! :solve_node_using_solved
        true
      end
#    rescue Error::UnknownValue
#      false
    end

  end

end


