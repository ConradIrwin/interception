require 'rubygems'
require 'thread'
require 'pry'

module RaiseAwareness

  class << self
    attr_accessor :mutex, :listeners
  end

  self.mutex = Mutex.new
  self.listeners = []

  def self.listen(for_block=nil, &listen_block)

    puts "FOOO"
    raise "no block given" unless listen_block || for_block
    listeners << listen_block || for_block
    start

    if listen_block && for_block
      begin
        for_block.call
      ensure
        unlisten listen_block
      end
    end
  end

  def self.unlisten(listen_block)
    listeners.delete listen_block
    stop if listeners.empty?
  end

  def self.rescue(e, binding)
    listeners.each do |l|
      l.call(e, binding)
    end
  end
end

if defined? Rubinius
  module RaiseAwareness
    def self.start
      class << Rubinius
        alias raise_with_no_awareness raise_exception

        def raise_exception(exc)
          bt = Rubinius::VM.backtrace(1, true).drop_while do |x|
            x.variables.method.file.to_s.start_with?("kernel/")
          end.first
          b = Binding.setup(bt.variables, bt.variables.method, bt.constant_scope, bt.variables.self, bt)

          RaiseAwareness.rescue(exc, b)
          raise_with_no_awareness(exc)
        end
      end
    end

    def self.stop
      alias raise_exception raise_with_no_awareness
    end
  end
elsif defined?(JRuby)
  puts "HIHIIH"
  $CLASSPATH << './org/pryrepl'
  java_import org.pryrepl.RaiseAwarenessEventHook

  module RaiseAwareness
    private
    def self.start
      puts "START"
      JRuby.runtime.add_event_hook(hook)
    end

    def self.stop
      JRuby.runtime.remove_event_hook(hook)
    end

    def self.hook
      @hook ||= RaiseAwarenessEventHook.new(proc do |e, b|
        self.rescue(e, b)
      end)
    end
  end

else
  require './ext/raise_awareness.so'
end

def pryly(&block)
  raised = []

  puts "listening"
  RaiseAwareness.listen(block) do |exception, binding|
    raised << [exception, binding]
  end

ensure
  if raised.last
    e, b = *raised.last
    $foo = e
    $bar = raised
    b.eval("_ex_ = $foo")
    b.eval("_raised_ = $bar")
    b.pry
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
__END__

require 'inline'
require 'pry'

class RaiseAwareness
  def initialize
    @bindings = []
  end

  def process(binding)
    @bindings << binding
  end

  def self.start(&block)
    $foo = new
    $foo.start(&block)
  end

  def start
    add_event_hook
    yield
  ensure
    remove_event_hook
    @bindings.last.pry
  end

  inline(:C) do |builder|
    builder.add_type_converter("rb_event_t", '', '')
    builder.add_type_converter("ID", '', '')
    builder.add_type_converter("NODE *", '', '')

    builder.include '<time.h>'
    builder.include '"ruby.h"'

    builder.prefix <<-'EOF'
      static VALUE event_hook_klass = Qnil;
      static ID method = 0;
      static int in_event_hook = 0;
      static VALUE argv[1];
    EOF

    builder.c_raw <<-'EOF'
    static void
    event_hook(rb_event_flag_t evflag, VALUE data, VALUE self, ID mid, VALUE klass) {

      printf("Hmm: %d %d %d\n", evflag, RUBY_EVENT_RAISE, evflag == RUBY_EVENT_RAISE);

      if (evflag == RUBY_EVENT_RAISE) {
        argv[0] = rb_funcall(self, rb_intern("binding"), 0, NULL);

        printf("Calling...: %p\n", data);

        rb_funcall2(data, rb_intern("process"), 1, argv);
      }
    }
    EOF

    builder.c <<-'EOF'
      void add_event_hook() {
        rb_add_event_hook(event_hook, RUBY_EVENT_RAISE, self);
      }
    EOF

    builder.c <<-'EOF'
      void remove_event_hook() {
        rb_remove_event_hook(event_hook);
        event_hook_klass = Qnil;
      }
    EOF
  end
end

RaiseAwareness.start do

  begin
    raise "foo"
  rescue => e
    raise e
  end

end
