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
          end.compact.inject do |accumulator, expression|
            Arel::Nodes::Or.new(accumulator, expression)
          end.to_sql
        end

        def pg_search_engines(pattern)
          Mincer.config.pg_search.engines.map do |engine_class|
            engine_class.new(pattern, search_statements)
          end
        end

        def search_statements
          @search_statements ||= options.any? { |option| option.any? } ? search_statements_from_options : default_search_statements
        end

        def search_statements_from_options
          options.map do |option|
            SearchStatement.new(option.delete(:columns), search_statement_default_options(option[:engines]).merge(option))
          end
        end

        # We use only text/string columns and avoid array
        def default_search_statements
          column_names = @relation.columns.reject do |column|
            ![:string, :text].include?(column.type) || column.array
          end.map do |column|
            "#{@relation.table_name}.#{column.name}"
          end
          [SearchStatement.new(column_names, search_statement_default_options([:fulltext]).merge(engines: [:fulltext]))]
        end

        def options
          Array.wrap(@mincer.send(:pg_search_options))
        end

        def search_statement_default_options(engines)
          (engines & [:fulltext, :trigram, :array]).each_with_object({}) do |engine, options|
            options.merge!(Mincer.config.pg_search.send("#{engine}_engine"))
          end
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
        config_accessor :engines do
          [Mincer::PgSearch::SearchEngines::Fulltext, Mincer::PgSearch::SearchEngines::Array, Mincer::PgSearch::SearchEngines::Trigram]
        end
      end

    end
  end
end

::Mincer.add_processor(:pg_search)
