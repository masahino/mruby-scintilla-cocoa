#import <Cocoa/Cocoa.h>
#import "Scintilla.h"
#import "ScintillaView.h"

#include <mruby.h>
#include <mruby/class.h>
#include <mruby/data.h>
#include <mruby/hash.h>
#include <mruby/string.h>
#include <mruby/variable.h>

typedef struct {
  ScintillaView *view;
  id delegate;
  mrb_state *mrb;
  mrb_value self;
} scintilla_cocoa_data;

@interface MrubyScintillaNotificationDelegate
  : NSObject <ScintillaNotificationProtocol>
{
  scintilla_cocoa_data *data;
}

- (id)initWithData:(scintilla_cocoa_data *)notificationData;
@end

static void
notification_hash_set(mrb_state *mrb, mrb_value hash, const char *key,
                      mrb_value value)
{
  mrb_hash_set(mrb, hash, mrb_str_new_cstr(mrb, key), value);
}

@implementation MrubyScintillaNotificationDelegate

- (id)initWithData:(scintilla_cocoa_data *)notificationData
{
  self = [super init];
  if (self != nil) {
    data = notificationData;
  }
  return self;
}

- (void)notification:(SCNotification *)notification
{
  mrb_state *mrb = data->mrb;
  mrb_value callback =
    mrb_iv_get(mrb, data->self, mrb_intern_lit(mrb, "@notification_callback"));
  mrb_value hash;

  if (mrb_nil_p(callback)) {
    return;
  }

  hash = mrb_hash_new_capa(mrb, 20);
  notification_hash_set(mrb, hash, "code",
                        mrb_int_value(mrb, notification->nmhdr.code));
  notification_hash_set(mrb, hash, "id",
                        mrb_int_value(mrb, notification->nmhdr.idFrom));
  notification_hash_set(mrb, hash, "position",
                        mrb_int_value(mrb, notification->position));
  notification_hash_set(mrb, hash, "ch",
                        mrb_int_value(mrb, notification->ch));
  notification_hash_set(mrb, hash, "modifiers",
                        mrb_int_value(mrb, notification->modifiers));
  notification_hash_set(mrb, hash, "modification_type",
                        mrb_int_value(mrb, notification->modificationType));
  if (notification->text != NULL) {
    notification_hash_set(
      mrb, hash, "text",
      mrb_str_new(mrb, notification->text, notification->length)
    );
  } else {
    notification_hash_set(mrb, hash, "text", mrb_nil_value());
  }
  notification_hash_set(mrb, hash, "length",
                        mrb_int_value(mrb, notification->length));
  notification_hash_set(mrb, hash, "lines_added",
                        mrb_int_value(mrb, notification->linesAdded));
  notification_hash_set(mrb, hash, "message",
                        mrb_int_value(mrb, notification->message));
  notification_hash_set(mrb, hash, "line",
                        mrb_int_value(mrb, notification->line));
  notification_hash_set(mrb, hash, "fold_level_now",
                        mrb_int_value(mrb, notification->foldLevelNow));
  notification_hash_set(mrb, hash, "fold_level_prev",
                        mrb_int_value(mrb, notification->foldLevelPrev));
  notification_hash_set(mrb, hash, "margin",
                        mrb_int_value(mrb, notification->margin));
  notification_hash_set(mrb, hash, "list_type",
                        mrb_int_value(mrb, notification->listType));
  notification_hash_set(mrb, hash, "x",
                        mrb_int_value(mrb, notification->x));
  notification_hash_set(mrb, hash, "y",
                        mrb_int_value(mrb, notification->y));
  notification_hash_set(mrb, hash, "token",
                        mrb_int_value(mrb, notification->token));
  notification_hash_set(
    mrb, hash, "annotation_lines_added",
    mrb_int_value(mrb, notification->annotationLinesAdded)
  );
  notification_hash_set(mrb, hash, "updated",
                        mrb_int_value(mrb, notification->updated));
  notification_hash_set(
    mrb, hash, "list_completion_method",
    mrb_int_value(mrb, notification->listCompletionMethod)
  );

  mrb_funcall(mrb, callback, "call", 1, hash);
}

@end

static void
scintilla_cocoa_free(mrb_state *mrb, void *pointer)
{
  scintilla_cocoa_data *data = (scintilla_cocoa_data *)pointer;

  (void)mrb;
  if (data != NULL) {
    data->view.delegate = nil;
    [data->delegate release];
    [data->view release];
    mrb_free(mrb, data);
  }
}

static const struct mrb_data_type scintilla_cocoa_type = {
  "ScintillaCocoa", scintilla_cocoa_free
};

static mrb_value
scintilla_cocoa_initialize(mrb_state *mrb, mrb_value self)
{
  scintilla_cocoa_data *data;

  data = (scintilla_cocoa_data *)mrb_malloc(mrb, sizeof(*data));
  data->view =
    [[ScintillaView alloc] initWithFrame:NSMakeRect(0, 0, 640, 480)];
  data->mrb = mrb;
  data->self = self;
  data->delegate =
    [[MrubyScintillaNotificationDelegate alloc] initWithData:data];
  data->view.delegate = data->delegate;

  DATA_PTR(self) = data;
  DATA_TYPE(self) = &scintilla_cocoa_type;
  return self;
}

static mrb_value
scintilla_cocoa_send_message(mrb_state *mrb, mrb_value self)
{
  scintilla_cocoa_data *data = (scintilla_cocoa_data *)DATA_PTR(self);
  ScintillaView *view = data->view;
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
  scintilla_cocoa_data *data = (scintilla_cocoa_data *)DATA_PTR(self);

  return mrb_int_value(mrb, (mrb_int)(intptr_t)data->view);
}

static mrb_value
scintilla_cocoa_set_notification_callback(mrb_state *mrb, mrb_value self)
{
  mrb_value callback;

  mrb_get_args(mrb, "o", &callback);
  if (!mrb_nil_p(callback) && !mrb_respond_to(mrb, callback,
                                               mrb_intern_lit(mrb, "call"))) {
    mrb_raise(mrb, E_ARGUMENT_ERROR, "callback must respond to call");
  }
  mrb_iv_set(
    mrb, self, mrb_intern_lit(mrb, "@notification_callback"), callback
  );
  return callback;
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
  mrb_define_method(
    mrb, cocoa, "notification_callback=",
    scintilla_cocoa_set_notification_callback, MRB_ARGS_REQ(1)
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
