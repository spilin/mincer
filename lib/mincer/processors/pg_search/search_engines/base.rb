module Mincer
  module PgSearch
    module SearchEngines
      class Base
        attr_reader :pattern, :search_statements

        def initialize(pattern, search_statements)
          @pattern, @search_statements = pattern, search_statements
        end

        def arel_group(sql_string = nil)
          sql_string = yield if block_given?
          arel_query = sql_string.is_a?(String) ? Arel.sql(sql_string) : sql_string
          Arel::Nodes::Grouping.new(arel_query)
        end

        def sanitize_column(term, sanitizers)
          ::Mincer::Processors::PgSearch::Sanitizer.sanitize_column(term, sanitizers)
        end

        def sanitize_string(term, sanitizers)
          ::Mincer::Processors::PgSearch::Sanitizer.sanitize_string(term, sanitizers)
        end

        def sanitize_string_quoted(term, sanitizers)
          ::Mincer::Processors::PgSearch::Sanitizer.sanitize_string_quoted(term, sanitizers)
        end

      end
    end
  end
end
