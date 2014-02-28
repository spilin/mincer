module Mincer
  module PgSearch
    module SearchEngines
      class Trigram < Base

        def conditions
          Arel::Nodes::Grouping.new(similarities_condition)
        end

        private

        attr_reader :pattern, :options, :columns

        def similarities_condition
          columns.map do |search_column|
            similarity(search_column).gteq(options[:trigram][:threshold] || DEFAULT_THRESHOLD)
          end.inject do |accumulator, expression|
            Arel::Nodes::Or.new(accumulator, expression)
          end
        end

        def similarity(column)
          Arel::Nodes::Grouping.new(
              Arel::Nodes::NamedFunction.new('similarity', [normalized_pattern, normalized_column(column)])
          )
        end

        def normalized_pattern
          Arel.sql(normalize(Mincer.connection.quote(pattern)))
        end

        def normalized_column(column)
          Arel::Nodes::Grouping.new(Arel.sql(normalize(column)))
        end
      end
    end
  end
end
