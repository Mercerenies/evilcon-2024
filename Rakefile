# frozen_string_literal: true

require_relative './ruby/codex/task'
require_relative './ruby/lists/playing_card_lists_task'
require_relative './ruby/lists/card_list'

CODICES = [
  Codex::Task.new('./card_game/playing_card/cards/*.gd', './card_game/playing_card/playing_card_codex.gd'),
].freeze

LISTS_FILE = Lists::PlayingCardListsTask.new('./card_game/playing_card/playing_card_lists.gd')

task default: %i[codex lists]

task codex: CODICES.map(&:output_path)

task lists: LISTS_FILE.output_path

file LISTS_FILE.output_path => Lists::CardList.input_files do
  LISTS_FILE.run
end

CODICES.each do |codex_task|
  file codex_task.output_path => codex_task.input_files do
    codex_task.run
  end
end
