# frozen_string_literal: true

require_relative './lists_file'
require_relative './entry_file_ext'
require_relative './card_list'

module Lists
  # Concrete runner which generates the lists needed for our library
  # of cards.
  class PlayingCardListsTask
    using EntryFileExt

    attr_reader :output_path

    def initialize(output_path)
      @output_path = output_path
    end

    def run
      puts "Generating lists file #{output_path}..."

      lists_file = ListsFile.new([
        CardList.new("BARRYS_ROBOTS") { |entry| entry.archetype?("ROBOT") and entry.cost == 2 },
      ])
      IO.write output_path, lists_file
    end
  end
end
