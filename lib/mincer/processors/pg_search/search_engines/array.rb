module Mincer
  module PgSearch
    module SearchEngines
      class Array < Base

        def conditions
          return nil unless prepared_search_statements.any?
          arel_group do
            prepared_search_statements.map do |search_statement|
              if search_statement.pattern = args[search_statement.param_name]
                terms_delimiter = search_statement.options[:any_word] ? '&&' : '@>'
                arel_group(Arel::Nodes::InfixOperation.new(terms_delimiter, document_for(search_statement), query_for(search_statement)))
              end
            end.compact.inject do |accumulator, expression|
              Arel::Nodes::Or.new(accumulator, expression)
            end
          end
        end

        private

        def document_for(search_statement)
          arel_group do
            search_statement.columns.map do |search_column|
              Arel.sql(search_column + '::text[]')
            end.inject do |accumulator, expression|
              Arel::Nodes::InfixOperation.new('||', accumulator, expression)
            end
          end
        end

        def query_for(search_statement)
          normalized_pattern = search_statement.pattern.split(%r{\s|,}).uniq.reject(&:empty?).map do |item|
            sanitize_string_quoted(item, search_statement.sanitizers).to_sql
          end.join(',')
          Arel.sql("ARRAY[#{normalized_pattern}]")
        end

      end

    end
  end
end