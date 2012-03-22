require 'spec_helper'
require 'pp'

describe "Basic Node" do
  def norm2 array, zero = 0
    array.inject(zero) { | v, e | v += e * e }
  end
  it "can construct nodes" do
    a = [ 1, 2, 3 ]
    n = norm2(a, RNSolve::Node::NumericConstant.new(0))
    # pp n
  end
  it "evaluate nodes" do
    a = [ 1, 2, 3 ]
    n = norm2(a, RNSolve::Node::NumericConstant.new(0))
    s = RNSolve::State.new
    s.clear!
    s.value(n).should == 14
  end
  it "should evaluate variables" do
    x = RNSolve::Node::NumericVariable.new(:x)
    a = [ 1, x, 3 ]
    n = norm2(a, RNSolve::Node::NumericConstant.new(0))
    pp x

    s = RNSolve::State.new
    s.clear!
    s.set!(x, 2)
    s.value?(x).should == true
    s.value(x).should == 2
    s.value(n).should == 14

    s.clear!
    s.set!(x, 3)
    s.value(n).should == 19
  end
end
