# frozen_string_literal: true

module Codex
  Entry = Struct.new(:id, :path, keyword_init: true) do
    def name
      File.basename(path, '.*').upcase
    end
  end
end
