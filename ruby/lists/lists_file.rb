# frozen_string_literal: true

require 'stringio'

module Lists
  # A file containing lists of card IDs.
  class ListsFile
    # Initializes a file from an array of CardList objects.
    def initialize(lists)
      @lists = lists
    end

    def output(file)
      constants = @lists.map(&:to_gd_constant)
      file.write <<~CODE
        ## THIS FILE WAS GENERATED BY AN AUTOMATED RUBY TASK!
        ## ANY MODIFICATIONS MADE TO THIS FILE MAY BE OVERWRITTEN!

        extends Node

        #{constants.join("\n\n")}
      CODE
    end

    def to_s
      io = StringIO.new
      output io
      io.string
    end
  end
end