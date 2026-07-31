module Scintilla
  class ScintillaCocoa
    def sci_set_lexer_language(language)
      sci_set_ilexer(Scintilla.create_lexer(language))
    end
  end
end
