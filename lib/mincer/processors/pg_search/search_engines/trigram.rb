module Mincer
  module PgSearch
    module SearchEngines
      class Trigram < Base

        def conditions
          arel_group do
            search_engine_statements.map do |search_statement|
              document_for(search_statement)
            end.inject do |accumulator, expression|
              Arel::Nodes::Or.new(accumulator, expression)
            end
          end.to_sql
        end

        private

        def search_engine_statements
          @search_engine_statements ||= self.search_statements.select do |search_statement|
            search_statement.options[:engines].try(:include?, :trigram)
          end
        end

        def document_for(search_statement)
          search_statement.columns.map do |search_column|
            similarity = Arel::Nodes::NamedFunction.new('similarity', [sanitize_column(search_column, search_statement.sanitizers), sanitize_string(pattern, search_statement.sanitizers)])
            arel_group(similarity.gteq(search_statement.threshold))
          end.inject do |accumulator, expression|
            Arel::Nodes::Or.new(accumulator, expression)
          end
        end

      end
    end
  end
end
