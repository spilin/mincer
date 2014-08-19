module Mincer
  module PgSearch
    module SearchEngines
      class Trigram < Base

        def conditions
          return nil unless prepared_search_statements.any?
          arel_group do
            join_expressions(prepared_search_statements.map { |search_statement| document_for(search_statement) }, :or)
          end
        end

        def rank
          return nil unless prepared_search_statements.any?
          arel_group do
            join_expressions(prepared_search_statements.map { |search_statement| rank_for(search_statement) }, :+)
          end
        end

        private


        def document_for(search_statement)
          documents = search_statement.columns.map do |search_column|
            similarity = Arel::Nodes::NamedFunction.new('similarity', [sanitize_column(search_column, search_statement.sanitizers(:document)), sanitize_string(search_statement.pattern, search_statement.sanitizers(:query))])
            arel_group(similarity.gteq(search_statement.threshold))
          end
          join_expressions(documents, :or)
        end

        def rank_for(search_statement)
          ranks = search_statement.columns.map do |search_column|
            Arel::Nodes::NamedFunction.new('similarity', [sanitize_column(search_column, search_statement.sanitizers(:document)), sanitize_string(search_statement.pattern, search_statement.sanitizers(:query))])
          end
          join_expressions(ranks, :+)
        end

      end
    end
  end
end
