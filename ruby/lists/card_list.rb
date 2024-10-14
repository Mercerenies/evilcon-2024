# frozen_string_literal: true

module Lists
  # A list of card EntryFile values, dynamically generated from the
  # card information available in the file system.
  class CardList
    include Enumerable

    attr_reader :name

    def initialize(name, filter_pred = nil, &block)
      @name = name
      @filter_pred = filter_pred || block
    end

    def to_a
      @to_a ||= calculate_values
    end

    def each(&block)
      to_a.each(&block)
    end

    def ids
      map(&:id)
    end

    def self.input_files
      Dir.glob('./card_game/playing_card/cards/*.gd')
    end

    def to_gd_constant
      "const #{name} = [#{ids.join(', ')}]"
    end

    private def calculate_values
      self.class.input_files
        .map { |path| Codex::EntryFile.new(path) }
        .select(&@filter_pred)
        .sort_by(&:id)
    end
  end
end
