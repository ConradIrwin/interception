require 'pry'
if defined? Rubinius
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

    def binding_of_caller(n)
      bt = Rubinius::VM.backtrace(1 + n, true).first

        b = Binding.setup(
                      bt.variables,
                      bt.variables.method,
                      bt.constant_scope,
                      bt.variables.self,
                      bt
                      )

        b.instance_variable_set(:@frame_description, bt.describe)

        b
    end
  end
else
  require './ext/raise_awareness.so'
end
module RaiseAwareness
  def self.listeners; @listeners ||= []; end

  def self.rescue(e, binding)
    listeners.each do |l|
      l.call(e, binding)
    end
  end

  def self.wrap
    raises = []
    listeners << proc{ |e, b| raises << [e, b] }
    yield
  ensure
    listeners.pop
    e, b = *raises.last
    if b
      $foo = e
      $bar = raises
      b.eval("_ex_ = $foo")
      b.eval("_raises_ = $bar")
      b.pry
    end
  end
end

RaiseAwareness.wrap do
  begin
    begin
      raise "foo"

    rescue => e
      raise "bar"
    end

  rescue => e
    "woo".wibble

  end
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
