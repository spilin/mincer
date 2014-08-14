# This and all processors are heavily influenced by pg_search(https://github.com/Casecommons/pg_search)
module Mincer
  module Processors
    module PgSearch
      class Processor

        def initialize(mincer)
          @mincer, @args, @relation = mincer, mincer.args, mincer.relation
        end

        def apply
          if Mincer.postgres?
            @relation = apply_pg_search(@relation, @args)
          else
            @relation
          end
        end

        def apply_pg_search(relation, args)
          relation.where(conditions(args)).order(rank(args))
        end

        def conditions(args)
          search_statements_conditions = search_statements.map do |search_statement|
            conditions = pg_search_engines(args, search_statement).map do |pg_search_engine|
              pg_search_engine.conditions
            end.compact
            join_conditions(conditions, options[:join_with])
          end.compact
          join_conditions(search_statements_conditions, options[:join_with]).try(:to_sql)
        end

        def rank(args)
          search_statements_conditions = search_statements.map do |search_statement|
            conditions = pg_search_engines(args, search_statement).map do |pg_search_engine|
              pg_search_engine.rank
            end.compact
            join_conditions(conditions, :+)
          end.compact
          join_conditions(search_statements_conditions, :+).try(:to_sql)
        end

        def pg_search_engines(args, search_statement)
          Mincer.config.pg_search.engines.map do |engine_class|
            engine_class.new(args, [search_statement])
          end
        end

        def search_statements
          @search_statements ||= params.any? { |param| param[:columns] } ? search_statements_from_params : default_search_statements
        end

        def search_statements_from_params
          params.map do |param|
            par = param.dup
            SearchStatement.new(par.delete(:columns), search_statement_default_options(param[:engines]).merge(par))
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

        def params
          Array.wrap(@mincer.send(:pg_search_params))
        end

        def options
          @mincer.send(:pg_search_options)
        end

        def search_statement_default_options(engines)
          (engines & [:fulltext, :trigram, :array]).inject({}) do |options, engine|
            options = Mincer.config.pg_search.send("#{engine}_engine").merge(options)
            options
          end
        end

        def join_conditions(expressions, join_with)
          case join_with
          when :and then Arel::Nodes::And.new(expressions)
          when :+ then expressions.inject { |accumulator, expression| Arel::Nodes::InfixOperation.new('+', accumulator, expression) }
          else expressions.inject { |accumulator, expression| Arel::Nodes::Or.new(accumulator, expression) }
          end
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

          def pg_search(params, options = {})
            class_eval <<-OPTIONS, __FILE__, __LINE__
            def pg_search_params
              @pg_search_params ||= #{params.inspect}
                end
            def pg_search_options
              @pg_search_options ||= #{options.inspect}
                end
            OPTIONS
          end
        end

        def pg_search_params
          @pg_search_params ||= {}
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
