module Mincer
  module PgSearch
    module SearchEngines
      class Trigram < Base
        @@default_threshold = nil

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
            if self.class.default_threshold == search_statement.threshold
              arel_group(join_expressions([sanitize_column(search_column, search_statement.sanitizers(:document)), sanitize_string(search_statement.pattern, search_statement.sanitizers(:query))], '%'))
            else
              arel_group(similarity_function(search_column, search_statement).gteq(search_statement.threshold))
            end
          end
          join_expressions(documents, :or)
        end

        def rank_for(search_statement)
          ranks = search_statement.columns.map do |search_column|
            similarity_function(search_column, search_statement)
          end
          join_expressions(ranks, :+)
        end

        def similarity_function(search_column, search_statement)
          Arel::Nodes::NamedFunction.new('similarity', [sanitize_column(search_column, search_statement.sanitizers(:document)), sanitize_string(search_statement.pattern, search_statement.sanitizers(:query))])
        end

        def self.default_threshold
          if @@default_threshold.nil?
            grab_default_threshold
          else
            @@default_threshold
          end
        end

        def self.grab_default_threshold
          @@default_threshold = ::Mincer.connection.execute('SELECT show_limit();').first['show_limit'].to_r
        end

      end
    end
  end
end
