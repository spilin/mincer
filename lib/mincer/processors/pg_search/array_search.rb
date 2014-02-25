module Mincer
  module PgSearch
    class ArraySearch

      def initialize(pattern, options)
        @pattern = pattern
        @options = options || {}
        @columns = options[:array_columns]
      end

      def conditions
        Arel::Nodes::Grouping.new(
            Arel::Nodes::InfixOperation.new('&&', array_typecast(arel_columns), arel_array)
        )
      end

      private

      attr_reader :pattern, :options, :columns

      def arel_columns
        Arel::Nodes::Grouping.new( Arel.sql(columns.join(' || '))  )
      end

      def array_typecast(node)
        Arel.sql("#{node.to_sql}::text[]")
      end

      def arel_array
        Arel::Nodes::NamedFunction.new('string_to_array', [normalized_pattern, ','])
      end

      def normalized_pattern
        @normalized_pattern ||= @pattern.split(%r{\s|,}).uniq.reject(&:empty?).join(',')
      end

    end

  end
end