module Mincer
  module PgSearch
    module SearchEngines
      class Array < Base
        def conditions
          arel_group do
            search_engine_statements.map do |search_statement|
              terms_delimiter = search_statement.options[:any_word] ? '&&' : '@>'
              Arel::Nodes::InfixOperation.new(terms_delimiter, document_for(search_statement), query_for(pattern, search_statement)).to_sql
            end.inject do |accumulator, expression|
              Arel::Nodes::Or.new(accumulator, expression)
            end
          end.to_sql
        end

        private

        def search_engine_statements
          @search_engine_statements ||= self.search_statements.select do |search_statement|
            search_statement.options[:engines].try(:include?, :array)
          end
        end

        def document_for(search_statement)
          arel_group do
            search_statement.columns.map do |search_column|
              Arel.sql(search_column)
            end.inject do |accumulator, expression|
              Arel::Nodes::InfixOperation.new('||', accumulator, expression)
            end
          end
        end

        def query_for(pattern, search_statement)
          normalized_pattern = pattern.split(%r{\s|,}).uniq.reject(&:empty?).map do |item|
            sanitize_string_quoted(item, search_statement.sanitizers).to_sql
          end.join(',')
          Arel.sql("ARRAY[#{normalized_pattern}]")
        end

      end

    end
  end
end