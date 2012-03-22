require "rnsolve/version"

module RNSolve
  class Error < ::Exception
    class Incomputable < self; end
    class UnknownValue < Incomputable; end
  end
end

require 'rnsolve/node'
require 'rnsolve/state'
require 'rnsolve/solver'
require 'rnsolve/numeric_node'

