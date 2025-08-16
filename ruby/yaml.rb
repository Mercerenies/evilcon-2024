# frozen_string_literal: true

require 'json'
require 'yaml'

require 'json-schema'

# YAML validation and conversion (to JSON) tools.
module Yaml
  DIALOGUE_VALIDATOR = JSON::Validator.new(File.read('datafiles/schemas/dialogue_schema.json'))

  # Load as YAML
  module_function def load(yaml_str)
    YAML.safe_load yaml_str
  end

  # Dump as JSON
  module_function def dump_json(obj)
    JSON.pretty_generate obj
  end
end
