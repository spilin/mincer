# Heavily influenced by pg_search(https://github.com/Casecommons/pg_search)
module Mincer
  module Processors
    module PgSearch
      class Processor
        def initialize(mincer)
          @mincer, @args, @relation = mincer, mincer.args, mincer.relation
        end

        def apply
          if Mincer.postgres? && @args['pattern'].present?
            @relation = apply_pg_search(@relation, @args['pattern'])
          else
            @relation
          end
        end

        def apply_pg_search(relation, pattern)
          @mincer.pg_search_options[:columns] ||= default_columns
          search_feature = Mincer::PgSearch::TSearch.new(pattern, @mincer.pg_search_options)
          relation.where(search_feature.conditions)
        end

        def default_columns
          table_name = @relation.table_name
          @relation.columns.map { |column| "#{table_name}.#{column.name}" if [:string, :text].include?(column.type) }.compact
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
    end
  end
end

::Mincer.add_processor(:pg_search)
