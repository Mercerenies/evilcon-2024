# frozen_string_literal: true

require_relative '../yaml'

require 'yaml'
require 'json'

require 'json-schema'

module Yaml
  # Concrete runner which generates the lists needed for our library
  # of cards.
  class YamlConversionTask
    attr_reader :input_path
    attr_reader :validator

    def initialize(input_path, validator: nil)
      @input_path = input_path
      @validator = validator
    end

    def run
      puts "Validating YAML for #{input_path} ..."

      yaml_data = Yaml.load(File.read(input_path))
      validator&.validate yaml_data

      puts "Writing YAML to #{output_path} ..."
      json_str = Yaml.dump_json(yaml_data)
      File.write output_path, json_str
    end

    def output_path
      dirname = File.dirname(input_path)
      basename = File.basename(input_path, '.*')
      "#{dirname}/#{basename}.json"
    end
  end
end
