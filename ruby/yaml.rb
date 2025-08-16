# frozen_string_literal: true

require 'json'
require 'yaml'

# YAML validation and conversion (to JSON) tools.
module Yaml
  # Load as YAML
  module_function def load(yaml_str)
    YAML.safe_load yaml_str
  end

  # Dump as JSON
  module_function def dump_json(obj)
    JSON.pretty_generate obj
  end
end
