# frozen_string_literal: true

module Codex
  module Helpers
    module_function def indent(lines, level = 4)
      spaces = ' ' * level
      lines.gsub(/^/, spaces)
    end
  end
end
