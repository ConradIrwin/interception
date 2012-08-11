require 'thread'


# Provides global facility for monitoring exceptions raised in your application.
module Interception

  class << self
    attr_accessor :mutex, :listeners, :rescueing
  end
  self.mutex = Mutex.new
  self.listeners = []
  self.rescueing = false

  # Listen for any exceptions raised.
  #
  # The listener block that you pass in will be executed as though inside Kernel#raise,
  # so your entire program is still actively running. If you have a gem like
  # pry-stack_explorer you can access the stack frames that lead to the exception
  # occurring.
  #
  # NOTE: Be careful when writing a listener, if your listener raises an
  #       exception it will mask the original exception.
  #
  # @example
  #
  #   # To report exceptions for the entire run of the program:
  #   Interception.listen do |exception, binding|
  #     Emailer.spam!('on-duty@startup.com', exception, binding.eval('self.class.name'))
  #   end
  #
  # @example
  #
  #   # To log exceptions for the duration of a given block.
  #   def log_exceptions(&block)
  #     Interception.listen(block) do |exception, binding|
  #       puts "#{binding.eval("self.inspect")} raised #{exception.inspect}"
  #     end
  #   end
  #
  # @example
  #
  #   # You can also turn listeners on and off manually
  #
  #   listener = Proc.new{ |exception, binding|
  #     binding.pry
  #   }
  #   Interception.listen(listener)
  #   Async::Redis.get("foo") do
  #     Interception.unlisten(listener)
  #   end
  #
  # @param [Proc] for_block (nil) If you pass for_block in, then you will only
  #                               intercept exceptions raised while that block
  #                               is running.
  # @param [Proc] listen_block    The block to call when an exception occurs,
  #                               takes two arguments, the exception and the
  #                               binding
  # @return [Object]              The return value of the for_block (if present)
  # @yield [Exception]
  # @yield [Binding]
  # @see {unlisten}
  def self.listen(for_block=nil, &listen_block)
    raise ArgumentError, "no block given" unless listen_block || for_block
    mutex.synchronize{
      start if listeners.empty?
      listeners << listen_block || for_block
    }

    if listen_block && for_block
      begin
        for_block.call
      ensure
        unlisten listen_block
      end
    else
      listen_block
    end
  end

  # Disable a previously added listener
  #
  # @param [Proc] listen_block  The listen block you wish to remove.
  def self.unlisten(listen_block)
    mutex.synchronize{
      listeners.delete listen_block
      stop if listeners.empty?
    }
  end

  # Called by platform-specific implementations whenever an exception is raised.
  #
  # The arguments will be forwarded on to all listeners added via {listen} that
  # haven't been removed via {unlisten}.
  #
  # For efficiency, this block will never be called unless there are active
  # listeners.
  #
  # @param [Exception] e  The exception that was raised
  # @param [Binding] binding  The binding from which it was raised
  def self.rescue(e, binding)
    return if rescueing
    self.rescueing = true
    listeners.each do |l|
      l.call(e, binding)
    end
  ensure
    self.rescueing = false
  end

  # Start sending events to rescue.
  # @see cross_platform.rb
  def self.start; raise NotImplementedError end

  # Stop sending events to rescue.
  # @see cross_platform.rb
  def self.stop; raise NotImplementedError end

  require File.expand_path('../cross_platform.rb', __FILE__)
end
