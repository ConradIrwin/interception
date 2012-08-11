require 'rubygems'
require 'interception'
require 'pry'
require 'pry-stack_explorer'
def pryly(&block)
  raised = []

  Interception.listen(block) do |exception, binding|
    raised << [exception, binding.callers]
  end

ensure
  if raised.last
    e, bindings = raised.last
    $foo = e
    $bar = raised
    bindings.first.eval("_ex_ = $foo")
    bindings.first.eval("_raised_ = $bar")
    bindings = bindings.drop_while { |b| b.eval("self") == Interception || b.eval("__method__") == :pryly }
    pry :call_stack => bindings
  end
end

pryly do

  def a
    begin
      begin
        raise "foo"

      rescue => e
        raise "bar"
      end

    rescue => e
      1 / 0

    end
  end
  a
end
