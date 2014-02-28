module Mincer
  module PgSearch
    module SearchEngines
      class Array < Base
        def conditions
          Arel::Nodes::Grouping.new(
              # <@
              Arel::Nodes::InfixOperation.new('&&', document, query)
          )
        end

        private

        def document
          Arel.sql("#{Arel::Nodes::Grouping.new(Arel.sql(normalized_columns)).to_sql}::text[]")
        end

        def normalized_columns
          columns.join(' || ')
        end

        def query
          Arel::Nodes::NamedFunction.new('string_to_array', [normalized_pattern, ','])
        end

        def normalized_pattern
          @pattern.split(%r{\s|,}).uniq.reject(&:empty?).map do |item|
            normalize(item)
          end.join(',')
        end


        def normalize(item)
          options[:ignore_case] ? item.downcase : item
        end

      end

    end
  end
end