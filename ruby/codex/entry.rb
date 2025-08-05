# frozen_string_literal: true

module Codex
  Entry = Struct.new(:id, :path, :limited, :rarity, keyword_init: true) do
    def name
      File.basename(path, '.*').upcase
    end

    def to_h
      {
        "id" => id,
        "name" => name,
        "path" => path,
        "limited" => limited,
        "rarity" => rarity,
      }
    end
  end
end
