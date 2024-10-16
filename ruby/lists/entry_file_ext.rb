# frozen_string_literal: true

module Lists
  # Refinements for Codex::EntryFile
  module EntryFileExt
    refine Codex::EntryFile do
      def cost
        return @cost unless @cost.nil?

        @cost = with_file { |f| find_cost f }
      end

      def archetypes
        return @archetypes unless @archetypes.nil?

        @archetypes = with_file { |f| find_archetypes f }
      end

      def archetype?(name)
        archetypes.include? name
      end

      def rarity
        return @rarity unless @rarity.nil?

        @rarity = with_file { |f| find_rarity f }
      end

      def title
        return @title unless @title.nil?

        @title = with_file { |f| find_title f }
      end

      private def find_cost(file)
        file.read =~ /^func get_star_cost\(\).*:\n\s+return (-?\d+)/ or return nil
        $1.to_i
      end

      private def find_archetypes(file)
        file.read =~ /^func get_base_archetypes\(\).*:\n\s+return \[([^\]]+)\]/ or return []
        $1.split(/,\s*/).map { |s| s.gsub(/^Archetype\./, '') }
      end

      private def find_rarity(file)
        file.read =~ /^func get_rarity\(\).*:\n\s+return (.+)/ or return nil
        $1.gsub(/^Rarity\./, '')
      end

      private def find_title(file)
        file.read =~ /^func get_title\(\).*:\n\s+return "([^"]+)"/ or return nil
        $1
      end
    end
  end
end
