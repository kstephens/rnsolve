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
    # pp x

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

  it "should solve variables" do
    x = RNSolve::Node::NumericVariable.new(:x)
    a = [ 1, x, 3 ]
    n = norm2(a, RNSolve::Node::NumericConstant.new(0))

    s = RNSolve::Solver.new
    #s.debug = true
    #s.state.debug = true
    s.set!(n, 14)
    s.value(x).should == RNSolve::Node::NumericSet[ -2, 2 ]
    pp s.stats if s.debug
    pp s.state.to_h if s.debug

    x = RNSolve::Node::NumericVariable.new(:x)
    a = [ 1, 2, x ]
    n = norm2(a, RNSolve::Node::NumericConstant.new(0))

    s = RNSolve::Solver.new
    # s.debug = true
    # s.state.debug = true
    s.set!(n, 14)
    s.value(x).should == RNSolve::Node::NumericSet[-3, 3]
  end

  it "should error on overconstrained variables" do
    x = RNSolve::Node::NumericVariable.new(:x)
    y = x + 1
    a = [ 1, x, y ]
    n = norm2(a, RNSolve::Node::NumericConstant.new(0))

    s = RNSolve::Solver.new
    s.debug = true
    # s.state.debug = true
    s.set!(n, 14)
    lambda { s.value(x) }.should raise_error(RNSolve::Error::UnknownValue)
  end

  it "should solve for subtraction." do
    x = RNSolve::Node::NumericVariable.new(:x)
    y = x - 3
    s = RNSolve::Solver.new
    s.debug = true
    # s.state.debug = true
    s.set!(y, 16)
    s.value(x).should == 19
  end

  it "should solve for division." do
    x = RNSolve::Node::NumericVariable.new(:x)
    y = x / 3
    s = RNSolve::Solver.new
    s.debug = true
    # s.state.debug = true
    s.set!(y, 16)
    s.value(x).should == 48
  end
end
