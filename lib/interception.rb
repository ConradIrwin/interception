require 'thread'

module Interception

  class << self
    attr_accessor :mutex, :listeners, :rescueing
  end

  self.mutex = Mutex.new
  self.listeners = []

  def self.listen(for_block=nil, &listen_block)
    raise "no block given" unless listen_block || for_block
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
    end
  end

  def self.unlisten(listen_block)
    mutex.synchronize{
      listeners.delete listen_block
      stop if listeners.empty?
    }
  end

  def self.rescue(e, binding)
    return if rescueing
    self.rescueing = true
    listeners.each do |l|
      l.call(e, binding)
    end
  ensure
    self.rescueing = false
  end

  if defined? Rubinius
    def self.start
      class << Rubinius
        alias raise_with_no_interception raise_exception

        def raise_exception(exc)
          bt = Rubinius::VM.backtrace(1, true).drop_while do |x|
            x.variables.method.file.to_s.start_with?("kernel/")
          end.first
          b = Binding.setup(bt.variables, bt.variables.method, bt.constant_scope, bt.variables.self, bt)

          Interception.rescue(exc, b)
          raise_with_no_interception(exc)
        end
      end
    end

    def self.stop
      class << Rubinius
        alias raise_exception raise_with_no_interception
      end
    end
  elsif defined?(JRuby)
    require 'java'
    $CLASSPATH << File.expand_path('../../ext/', __FILE__)
    java_import org.pryrepl.InterceptionEventHook

    def self.start
      old_verbose = $VERBOSE
      $VERBOSE = nil
      JRuby.runtime.add_event_hook(hook)
    ensure
      $VERBOSE  = old_verbose
    end

    def self.stop
      JRuby.runtime.remove_event_hook(hook)
    end

    def self.hook
      @hook ||= InterceptionEventHook.new(proc do |e, b|
        self.rescue(e, b)
      end)
    end

  else
    require File.expand_path('../../ext/interception.so', __FILE__)
  end
end
