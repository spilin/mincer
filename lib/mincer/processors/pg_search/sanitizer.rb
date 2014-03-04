module Mincer
  module Processors
    module PgSearch
      class Sanitizer
        AVAILABLE_SANITIZERS = [:ignore_case, :ignore_accent, :coalesce]
        attr_accessor :term, :sanitizers, :sanitized_term

        def initialize(term, sanitizers)
          @term, @sanitizers = term, sanitizers
        end

        def sanitize_column
          @sanitized_column ||= sanitize(Arel.sql(@term))
        end

        def sanitize_string
          @sanitized_string ||= sanitize(Arel::Nodes::NamedFunction.new('concat', [@term])).to_sql
        end

        def sanitize(node)
          sanitizers.inject(node) do |query, sanitizer|
            query = self.class.send(sanitizer, query) if AVAILABLE_SANITIZERS.include?(sanitizer)
            query
          end
        end

        def self.sanitize_column(term, *sanitizers)
          new(term, *sanitizers).sanitize_column
        end

        def self.sanitize_string(term, *sanitizers)
          new(term, *sanitizers).sanitize_string
        end

        def self.ignore_case(term)
          Arel::Nodes::NamedFunction.new('lower', [term])
        end

        def self.ignore_accent(term)
          Arel::Nodes::NamedFunction.new('unaccent', [term])
        end

        def self.coalesce(term, val = '')
          Arel::Nodes::NamedFunction.new('coalesce', [term, val])
        end

      end
    end
  end
end
