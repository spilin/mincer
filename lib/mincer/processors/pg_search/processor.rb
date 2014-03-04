# This and all processors are heavily influenced by pg_search(https://github.com/Casecommons/pg_search)
module Mincer
  module Processors
    module PgSearch
      class Processor

        def initialize(mincer)
          @mincer, @args, @relation = mincer, mincer.args, mincer.relation
        end

        def apply
          if Mincer.postgres? && @args[param_name].present?
            @relation = apply_pg_search(@relation, @args[param_name])
          else
            @relation
          end
        end

        def apply_pg_search(relation, pattern)
          relation.where(conditions(pattern))
        end

        def conditions(pattern)
          pg_search_engines(pattern).map do |pg_search_engine|
            pg_search_engine.conditions
          end.inject do |accumulator, expression|
            Arel::Nodes::Or.new(accumulator, expression)
          end.to_sql
        end

        def pg_search_engines(pattern)
          [
              Mincer::PgSearch::SearchEngines::Fulltext,
              #Mincer::PgSearch::SearchEngines::Array,
              #Mincer::PgSearch::SearchEngines::Trigram
          ].map do |engine_class|
            engine_class.new(pattern, columns)
          end
        end

        def columns
          @columns ||= columns_in_options? ? search_columns : default_search_columns
        end

        def search_columns
          Array.wrap(options).each_with_object([]) do |option, search_columns|
            option.delete(:columns).each do |column|
              search_columns << SearchColumn.new(full_name: column, options: option)
            end
          end
        end

        # We use only text/string columns and avoid array
        def default_search_columns
          table_name = @relation.table_name
          @relation.columns.reject do |column|
            ![:string, :text].include?(column.type) || column.array
          end.map do |column|
            SearchColumn.new(full_name: "#{table_name}.#{column.name}", options: ::Mincer.config.pg_search.fulltext_engine.merge(engines: [:fulltext]))
          end
        end

        def options
          @mincer.send(:pg_search_options)
        end

        def columns_in_options?
          return false if options.empty?
          Array.wrap(options).all? { |option| option[:columns].present? && option[:columns].any? }
        end

        def param_name
          Mincer.config.pg_search.param_name
        end
      end

      module Options
        extend ActiveSupport::Concern

        module ClassMethods
          def skip_pg_search!
            active_processors.delete(Mincer::Processors::PgSearch::Processor)
          end

          def skip_search!
            skip_pg_search!
          end
        end

        def pg_search_options
          @pg_search_options ||= {}
        end
      end

      class Configuration
        include ActiveSupport::Configurable
        config_accessor :param_name do
          'pattern'
        end
        config_accessor :fulltext_engine do
          { ignore_accent: true, any_word: false, dictionary: :simple, ignore_case: false }
        end
        config_accessor :trigram_engine do
          { ignore_accent: true, threshold: 0.3 }
        end
        config_accessor :array_engine do
          { ignore_accent: true, any_word: true }
        end
      end

    end
  end
end

::Mincer.add_processor(:pg_search)
