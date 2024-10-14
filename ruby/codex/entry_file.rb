# frozen_string_literal: true

module Codex
  # A file which represents a single entry for a codex.
  class EntryFile
    attr_reader :file_path

    def initialize(file_path)
      @file_path = file_path
    end

    def with_file(&block)
      File.open(file_path, "r", &block)
    end

    def ignored?
      return @ignored unless @ignored.nil?

      @ignored = with_file do |f|
        f.each_line.any?(/CODEX: \s* IGNORE/x)
      end
    end

    def id
      return @id unless @id.nil?

      @id = with_file { |f| find_id f }
    end

    private def find_id(file)
      file.read =~ /^func get_id\(\).*:\n\s+return (-?\d+)/ or return nil
      $1.to_i
    end
  end
end
