module Mincer
  module PgSearch
    class SearchEngine

      def normalize(sql_expression)
        sql_node = sql_node(sql_expression)

        if options[:ignore_accent] && ::Mincer.pg_extension_installed?(:unaccent)
          sql_node = Arel::Nodes::NamedFunction.new('unaccent', [sql_node])
        end

        if options[:ignore_case]
          sql_node = Arel::Nodes::NamedFunction.new('lower', [sql_node])
        end

        sql_node.try(:to_sql) || sql_node.try(:to_s)
      end

      def sql_node(sql_expression)
        case sql_expression
        when Arel::Nodes::Node
          sql_expression
        else
          Arel.sql(sql_expression)
        end
      end

    end
  end
end
