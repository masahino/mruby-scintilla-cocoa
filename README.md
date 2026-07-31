# mruby-scintilla-cocoa

mruby bindings for the Cocoa implementation of
[Scintilla](https://www.scintilla.org/).

## Initial scope

This repository provides the platform bridge between mruby and
`ScintillaView`:

- create a `ScintillaView`;
- send `SCI_*` messages from mruby;
- use the typed message helpers provided by `mruby-scintilla-base`, including
  text, line, text-range, document, and lexer-pointer operations;
- receive `SCN_*` notifications in mruby;
- expose the native `NSView` pointer to a macOS application host.

Window management, menus, dialogs, and the application event loop belong in
the future `mruby-bin-mrbmacs-cocoa` frontend.

## Build

The build requires macOS, Xcode, Ruby, and Git.

```sh
rake
```

mruby defaults to version 4.0.0. Override it when needed:

```sh
MRUBY_VERSION=master rake
```

## Ruby API

```ruby
view = Scintilla::ScintillaCocoa.new
view.notification_callback = lambda do |notification|
  puts notification["code"]
end
view.send_message(Scintilla::SCI_SETTEXT, 0, "hello")
view.native_handle
```

`ScintillaCocoa` inherits the dynamic `SCI_*` API from
`Scintilla::ScintillaBase`. Specialized messages return Ruby values instead
of exposing native buffers and pointers directly:

```ruby
view.sci_set_text("first\nsecond")
view.sci_get_text(view.sci_get_length + 1) # => "first\nsecond"
view.sci_get_line(1)                       # => "second"

document = view.sci_get_docpointer
other_view = Scintilla::ScintillaCocoa.new
other_view.sci_add_refdocument(document)
other_view.sci_set_docpointer(document)

lexer = Scintilla.create_lexer("ruby")
view.sci_set_ilexer(lexer)
view.sci_get_lexer_language                # => "ruby"
```

For compatibility with the other mruby-scintilla frontends, the lexer can also
be selected directly by language name:

```ruby
view.sci_set_lexer_language("ruby")
```

Document pointers are represented by `Scintilla::Document` objects. Keep the
normal Scintilla reference-counting rules when sharing a document between
multiple views.

The notification hash uses the same string keys as the other mrbmacs
frontends, including `code`, `position`, `ch`, `modification_type`, `text`,
`length`, `lines_added`, `line`, `margin`, and `updated`. Assign `nil` to
`notification_callback` to stop delivery.

`native_handle` is intended for the native Cocoa frontend and must not outlive
the `ScintillaCocoa` object.
