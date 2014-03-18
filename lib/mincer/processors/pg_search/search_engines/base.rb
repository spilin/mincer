module Mincer
  module PgSearch
    module SearchEngines
      class Base
        attr_reader :args, :search_statements

        def initialize(args, search_statements)
          @args, @search_statements = ::ActiveSupport::HashWithIndifferentAccess.new(args), search_statements
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

        def search_engine_statements
          @search_engine_statements ||= self.search_statements.select do |search_statement|
            search_statement.options[:engines].try(:include?, engine_sym)
          end
        end

        def prepared_search_statements
          @prepared_search_statements ||= search_engine_statements.map do |search_statement|
            search_statement.extract_pattern_from(args)
            search_statement.pattern.present? ? search_statement : nil
          end.compact
        end

        # Redefine this method in subclass if your engine name does not match class
        def engine_sym
          @engine_sym ||= self.class.name.to_s.demodulize.underscore.to_sym
        end

      end
    end
  end
end
