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

        # Redefine this method in subclass if your engine name does not match class
        def engine_sym
          @engine_sym ||= self.class.name.to_s.demodulize.underscore.to_sym
        end

        def search_engine_statements_valid?
          search_engine_statements.any? && search_engine_statements.all?(&:pattern_present?)
        end

        # This method executes before conditions are generated, override it if you need more
        # the just extract pattern from args and saving it to instance variable.
        def prepare_search_statements
          search_engine_statements.each do |search_statement|
            search_statement.extract_pattern_from(args)
          end
        end

      end
    end
  end
end
