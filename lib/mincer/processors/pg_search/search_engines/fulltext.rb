module Mincer
  module PgSearch
    module SearchEngines
      class Fulltext < Base
        DISALLOWED_TSQUERY_CHARACTERS = /[!(:&|)'?\\]/

        def conditions
          return nil unless prepared_search_statements.any?
          arel_group do
            documents = prepared_search_statements.map do |search_statement|
              ts_query = ts_query_for(search_statement)
              ts_vectors_for(search_statement).map do |ts_vector|
                arel_group(Arel::Nodes::InfixOperation.new('@@', ts_vector, ts_query))
              end
            end.flatten

            join_expressions(documents, :or)
          end
        end

        def rank
          return nil unless prepared_search_statements.any?
          arel_group do
            ranks = prepared_search_statements.map do |search_statement|
              ts_query = ts_query_for(search_statement)
              ts_vectors_for(search_statement).map do |ts_vector|
                Arel::Nodes::NamedFunction.new('ts_rank', [ts_vector, ts_query])
              end
            end.flatten

            join_expressions(ranks, '+')
          end
        end

        private

        def prepared_search_statements
          @prepared_search_statements ||= search_engine_statements.map do |search_statement|
            pattern = args[search_statement.param_name]
            search_statement.pattern = pattern && pattern.gsub(DISALLOWED_TSQUERY_CHARACTERS, ' ').split(' ').compact
            search_statement.pattern.present? && search_statement.pattern.any? ? search_statement : nil
          end.compact
        end

        def ts_vectors_for(search_statement)
          sanitizers = search_statement.sanitizers(:document)
          # sanitizers += [:coalesce] if (search_statement.columns.size > 1)
          documents =  search_statement.columns.map do |search_column|
            sanitized_term = sanitize_column(search_column, sanitizers)
            ts_vector = Arel::Nodes::NamedFunction.new('to_tsvector', [quote(search_statement.dictionary), sanitized_term])
          end
        end

        def ts_query_for(search_statement)
          terms_delimiter = search_statement.options[:any_word] ? '|' : '&'
          tsquery = search_statement.terms.map do |term|
            _term = search_statement.options[:prefix_matching] ? "#{term}:*" : term
            sanitize_string_quoted(_term, search_statement.sanitizers(:query)).to_sql
          end.join(" || ' #{terms_delimiter} ' || ")
          Arel::Nodes::NamedFunction.new('to_tsquery', [quote(search_statement.dictionary), Arel.sql(tsquery)])
        end
      end

    end
  end
end
