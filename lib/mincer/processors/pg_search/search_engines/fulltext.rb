module Mincer
  module PgSearch
    module SearchEngines
      class Fulltext < Base
        DISALLOWED_TSQUERY_CHARACTERS = /['?\\:]/

        def conditions
          arel_group do
            search_engine_statements.map do |search_statement|
              arel_group(Arel::Nodes::InfixOperation.new('@@', arel_group(document_for(search_statement)), arel_group(query_for(pattern, search_statement)))).to_sql
            end.join(' OR ')
          end.to_sql
        end

        private

        def search_engine_statements
          @search_engine_statements ||= self.search_statements.select do |search_statement|
            search_statement.options[:engines].try(:include?, :fulltext)
          end
        end

        def document_for(search_statement)
          search_statement.columns.map do |search_column|
            sanitized_term = sanitize_column(search_column, search_statement.sanitizers)
            Arel::Nodes::NamedFunction.new('to_tsvector', [search_statement.dictionary, sanitized_term]).to_sql
          end.join(' || ')
        end

        def query_for(pattern, search_statement)
          terms_delimiter = search_statement.options[:any_word] ? '|' : '&'
          terms = pattern.gsub(DISALLOWED_TSQUERY_CHARACTERS, ' ').split(' ').compact
          tsquery_sql = Arel.sql(terms.map { |term| sanitize_string(term, search_statement.sanitizers) }.join(" || ' #{terms_delimiter} ' || "))
          Arel::Nodes::NamedFunction.new('to_tsquery', [search_statement.dictionary, tsquery_sql]).to_sql
        end

      end

    end
  end
end