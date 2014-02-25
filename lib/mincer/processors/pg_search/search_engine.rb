module Mincer
  module PgSearch
    class SearchEngine

      # { :ignore_accent => true } in options
      def normalize(sql_expression)
        return sql_expression unless options[:ignore_accent] && ::Mincer.pg_extension_installed?(:unaccent)

        sql_node = case sql_expression
                   when Arel::Nodes::Node
                     sql_expression
                   else
                     Arel.sql(sql_expression)
                   end

        Arel::Nodes::NamedFunction.new('unaccent', [sql_node]).to_sql
      end

    end
  end
end
