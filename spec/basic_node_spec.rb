require 'spec_helper'
require 'pp'

describe "Basic Node" do
  it "Node construction" do
    def norm2 array, zero = 0
      array.inject(zero) { | v, e | v += e * e }
    end
    a = [ 1, 2, 3 ]
    x = norm2(a, RNSolve::Node::NumericConstant.new(0))
    pp x
  end
end
