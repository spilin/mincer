module Mincer
  module PgSearch
    class ArraySearch < SearchEngine

      def initialize(pattern, options)
        @pattern = pattern
        @options = options || {}
        @columns = options[:array_columns]
      end

      def conditions
        Arel::Nodes::Grouping.new(
            # <@
            Arel::Nodes::InfixOperation.new('&&', document, query)
        )
      end

      private

      attr_reader :pattern, :options, :columns

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