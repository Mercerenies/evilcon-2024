# frozen_string_literal: true

require_relative './ruby/codex/task'

CODICES = [
  Codex::Task.new('./card_game/playing_card/cards/*.gd', './card_game/playing_card/playing_card_codex.gd'),
].freeze

task default: %i[codex]

task codex: CODICES.map(&:output_path)

CODICES.each do |codex_task|
  file codex_task.output_path => codex_task.input_files do
    codex_task.run
  end
end
