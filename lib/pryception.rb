require 'rubygems'
require 'interception'
require 'pry'

begin
  require 'pry-stack_explorer'
rescue LoadError
end

module Interception

  class << self

    # Intercept all exceptions that arise in the block and start a Pry session
    # at the fail site.
    def prycept(&block)
      raised = []

      Interception.listen(block) do |exception, binding|
        if defined?(PryStackExplorer)
          raised << [exception, binding.callers]
        else
          raised << [exception, Array(binding)]
        end
      end

    ensure
      if raised.any?
        exception, bindings = raised.last
        enter_exception_context(exception, bindings)
      end
    end

    private

    # Sanitize the call stack.
    # @param [Array<Binding>] bindings The call stack.
    def prune_call_stack!(bindings)
      bindings.delete_if { |b| b.eval("self") == self || b.eval("__method__") == :prycept }
    end

    # Start a Pry session in the context of the exception.
    # @param [Exception] exception The exception.
    # @param [Array<Binding>] bindings The call stack.
    def enter_exception_context(exception, bindings)
      inject_local("_ex_", exception, bindings.first)
      inject_local("_raised_", [exception, bindings.first], bindings.first)

      prune_call_stack!(bindings)
      if defined?(PryStackExplorer)
        pry :call_stack => bindings
      else
        bindings.first.pry
      end
    end

    # Inject a local variable into a binding.
    def inject_local(var, object, binding)
      Thread.current[:__intercept_var__] = object
      binding.eval("#{var} = Thread.current[:__intercept_var__]")
    ensure
      Thread.current[:__intercept_var__] = nil
    end
  end
end

