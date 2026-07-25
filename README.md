# mruby-scintilla-cocoa

mruby bindings for the Cocoa implementation of
[Scintilla](https://www.scintilla.org/).

## Initial scope

This repository provides the platform bridge between mruby and
`ScintillaView`:

- create a `ScintillaView`;
- send `SCI_*` messages from mruby;
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
view.send_message(Scintilla::SCI_SETTEXT, 0, "hello")
view.native_handle
```

`native_handle` is intended for the native Cocoa frontend and must not outlive
the `ScintillaCocoa` object.

