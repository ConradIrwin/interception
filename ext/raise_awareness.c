#include "ruby.h"

static VALUE rb_mRaiseAwareness;
static VALUE argv[1];

void
raise_awareness_hook(rb_event_flag_t evflag, VALUE data, VALUE self, ID mid, VALUE klass)
{
    VALUE binding = rb_funcall(self, rb_intern("binding"), 0, NULL);
    rb_funcall(data, rb_intern("rescue"), 2, rb_errinfo(), binding);
}

void
Init_raise_awareness()
{
    rb_mRaiseAwareness = rb_define_module("RaiseAwareness");
    rb_add_event_hook(raise_awareness_hook, RUBY_EVENT_RAISE, rb_mRaiseAwareness);
}
