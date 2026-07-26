assert('Scintilla::ScintillaCocoa notification callback') do
  view = Scintilla::ScintillaCocoa.new
  notifications = []

  view.notification_callback = lambda do |notification|
    notifications << notification
  end
  view.sci_set_text('hello')

  modified = notifications.find do |notification|
    notification['code'] == Scintilla::SCN_MODIFIED
  end

  assert_false modified.nil?
  assert_true modified.key?('position')
  assert_true modified.key?('modification_type')
  assert_true modified.key?('text')
  assert_true modified.key?('length')
  assert_true modified.key?('lines_added')
end

assert('Scintilla::ScintillaCocoa disables notification callback with nil') do
  view = Scintilla::ScintillaCocoa.new
  notifications = []

  view.notification_callback = lambda do |notification|
    notifications << notification
  end
  view.notification_callback = nil
  view.sci_set_text('hello')

  assert_equal [], notifications
end

assert('Scintilla::ScintillaCocoa rejects an invalid notification callback') do
  view = Scintilla::ScintillaCocoa.new

  assert_raise(ArgumentError) do
    view.notification_callback = Object.new
  end
end

assert('Scintilla::ScintillaCocoa gets its document pointer') do
  view = Scintilla::ScintillaCocoa.new

  assert_kind_of Scintilla::Document, view.sci_get_docpointer
end

assert('Scintilla::ScintillaCocoa switches document pointers') do
  view = Scintilla::ScintillaCocoa.new
  original_document = view.sci_get_docpointer

  view.sci_set_docpointer(nil)
  assert_not_equal original_document, view.sci_get_docpointer
end

assert('Scintilla::ScintillaCocoa adds a document reference') do
  view = Scintilla::ScintillaCocoa.new
  document = view.sci_get_docpointer

  assert_equal 0, view.sci_add_refdocument(document)
end

assert('Scintilla::ScintillaCocoa gets text') do
  view = Scintilla::ScintillaCocoa.new
  view.sci_set_text('abcdefg')

  assert_equal 'abc', view.sci_get_text(3)
end

assert('Scintilla::ScintillaCocoa gets target text and a text range') do
  view = Scintilla::ScintillaCocoa.new
  view.sci_set_text('abcdefg')
  view.sci_set_target_start(1)
  view.sci_set_target_end(5)

  assert_equal 'bcde', view.sci_get_target_text
  assert_equal 'cde', view.sci_get_text_range(2, 5)
end

assert('Scintilla::ScintillaCocoa gets the current line and a line') do
  view = Scintilla::ScintillaCocoa.new
  view.sci_set_text("abc\nxyz")
  view.sci_goto_pos(2)

  assert_equal ["abc\n", 2], view.sci_get_curline
  assert_equal 'xyz', view.sci_get_line(1)
end

assert('Scintilla::ScintillaCocoa sets a lexer pointer') do
  view = Scintilla::ScintillaCocoa.new
  lexer = Scintilla.create_lexer('ruby')

  view.sci_set_ilexer(lexer)
  assert_equal 'ruby', view.sci_get_lexer_language
end
