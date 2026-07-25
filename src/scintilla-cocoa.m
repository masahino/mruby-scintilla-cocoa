#import <Cocoa/Cocoa.h>
#import "Scintilla.h"
#import "ScintillaView.h"

#include <mruby.h>
#include <mruby/class.h>
#include <mruby/data.h>
#include <mruby/string.h>

static void
scintilla_cocoa_free(mrb_state *mrb, void *pointer)
{
  (void)mrb;
  if (pointer != NULL) {
    [(ScintillaView *)pointer release];
  }
}

static const struct mrb_data_type scintilla_cocoa_type = {
  "ScintillaCocoa", scintilla_cocoa_free
};

static mrb_value
scintilla_cocoa_initialize(mrb_state *mrb, mrb_value self)
{
  ScintillaView *view;

  view = [[ScintillaView alloc] initWithFrame:NSMakeRect(0, 0, 640, 480)];
  DATA_PTR(self) = view;
  DATA_TYPE(self) = &scintilla_cocoa_type;
  return self;
}

static mrb_value
scintilla_cocoa_send_message(mrb_state *mrb, mrb_value self)
{
  ScintillaView *view = (ScintillaView *)DATA_PTR(self);
  mrb_int message;
  mrb_value wparam_value = mrb_nil_value();
  mrb_value lparam_value = mrb_nil_value();
  uptr_t wparam = 0;
  sptr_t lparam = 0;

  mrb_get_args(mrb, "i|oo", &message, &wparam_value, &lparam_value);

  if (message < SCI_START) {
    mrb_raise(mrb, E_ARGUMENT_ERROR, "invalid Scintilla message");
  }

  if (mrb_integer_p(wparam_value)) {
    wparam = (uptr_t)mrb_integer(wparam_value);
  } else if (mrb_string_p(wparam_value)) {
    wparam = (uptr_t)RSTRING_PTR(wparam_value);
  } else if (mrb_true_p(wparam_value)) {
    wparam = 1;
  }

  if (mrb_integer_p(lparam_value)) {
    lparam = (sptr_t)mrb_integer(lparam_value);
  } else if (mrb_string_p(lparam_value)) {
    lparam = (sptr_t)RSTRING_PTR(lparam_value);
  } else if (mrb_true_p(lparam_value)) {
    lparam = 1;
  }

  return mrb_int_value(
    mrb,
    [view message:(unsigned int)message wParam:wparam lParam:lparam]
  );
}

static mrb_value
scintilla_cocoa_native_handle(mrb_state *mrb, mrb_value self)
{
  return mrb_int_value(mrb, (mrb_int)(intptr_t)DATA_PTR(self));
}

void
mrb_mruby_scintilla_cocoa_gem_init(mrb_state *mrb)
{
  struct RClass *scintilla = mrb_module_get(mrb, "Scintilla");
  struct RClass *base =
    mrb_class_get_under(mrb, scintilla, "ScintillaBase");
  struct RClass *cocoa =
    mrb_define_class_under(mrb, scintilla, "ScintillaCocoa", base);

  MRB_SET_INSTANCE_TT(cocoa, MRB_TT_DATA);
  mrb_define_method(
    mrb, cocoa, "initialize",
    scintilla_cocoa_initialize, MRB_ARGS_NONE()
  );
  mrb_define_method(
    mrb, cocoa, "send_message",
    scintilla_cocoa_send_message, MRB_ARGS_ARG(1, 2)
  );
  mrb_define_method(
    mrb, cocoa, "native_handle",
    scintilla_cocoa_native_handle, MRB_ARGS_NONE()
  );

  mrb_define_const(
    mrb, scintilla, "PLATFORM",
    mrb_symbol_value(mrb_intern_lit(mrb, "COCOA"))
  );
}

void
mrb_mruby_scintilla_cocoa_gem_final(mrb_state *mrb)
{
  (void)mrb;
}

