#include "ruby.h"

static VALUE rb_mRaiseAwareness;

#ifdef RUBY_19

void
raise_awareness_hook(rb_event_flag_t evflag, VALUE data, VALUE self, ID mid, VALUE klass)
{
    VALUE binding = rb_funcall(rb_mKernel, rb_intern("binding"), 0, NULL);
    rb_funcall(rb_mRaiseAwareness, rb_intern("rescue"), 2, rb_errinfo(), binding);
}

VALUE
raise_awareness_start(VALUE self)
{
    rb_add_event_hook(raise_awareness_hook, RUBY_EVENT_RAISE, rb_mRaiseAwareness);
}

#else

#include "node.h"

void
raise_awareness_hook(rb_event_t event, NODE *node, VALUE self, ID mid, VALUE klass)
{
    VALUE binding = rb_funcall(rb_mKernel, rb_intern("binding"), 0, NULL);
    rb_funcall(rb_mRaiseAwareness, rb_intern("rescue"), 2, ruby_errinfo, binding);
}

VALUE
raise_awareness_start(VALUE self)
{
    rb_add_event_hook(raise_awareness_hook, RUBY_EVENT_RAISE);
}

#endif

VALUE
raise_awareness_stop(VALUE self)
{
    rb_remove_event_hook(raise_awareness_hook);
    return Qnil;
}

void
Init_raise_awareness()
{
    rb_mRaiseAwareness = rb_define_module("RaiseAwareness");
    rb_define_singleton_method(rb_mRaiseAwareness, "start", raise_awareness_start, 0);
    rb_define_singleton_method(rb_mRaiseAwareness, "stop", raise_awareness_start, 0);
}
