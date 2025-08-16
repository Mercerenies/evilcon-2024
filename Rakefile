# frozen_string_literal: true

require_relative './ruby/codex/task'
require_relative './ruby/lists/playing_card_lists_task'
require_relative './ruby/lists/card_list'
require_relative './ruby/yaml/yaml_conversion_task'

CODICES = [
  Codex::Task.new('./card_game/playing_card/cards/*.gd', './card_game/playing_card/playing_card_codex.gd'),
  Codex::Task.new('./card_game/playing_card/cards/*.gd', './codex_metadata.yaml'),
].freeze

LISTS_FILE = Lists::PlayingCardListsTask.new('./card_game/playing_card/playing_card_lists.gd')

DIALOGUE_JSON_FILES = Dir.glob('./datafiles/dialogue/*.yaml')
                        .map { |input| Yaml::YamlConversionTask.new(input) }

task default: %i[codex lists yaml]

task codex: CODICES.map(&:output_path)

task lists: LISTS_FILE.output_path

task yaml: [:dialogue]

task dialogue: DIALOGUE_JSON_FILES.map(&:output_path)

file LISTS_FILE.output_path => Lists::CardList.input_files do
  LISTS_FILE.run
end

CODICES.each do |codex_task|
  file codex_task.output_path => codex_task.input_files do
    codex_task.run
  end
end

DIALOGUE_JSON_FILES.each do |dialogue_task|
  file dialogue_task.output_path => dialogue_task.input_path do
    dialogue_task.run
  end
end
