module Mincer
  module Processors
    module PgJsonDumper
      class Processor

        def initialize(mincer, options = {})
          @mincer, @args, @relation, @options = mincer, mincer.args, mincer.relation, options
        end

        def apply
          @relation
        end

        def to_json
          if dump_supported?
            result = Mincer.connection.select_all(json_query).first['json']
            return result unless @options[:singularize]
            return (result[1..-2].presence || '{}') unless @options[:root]
            (result.sub('[', '').sub(/(\])}$/, '}').presence || '{}')
          else
            warn 'To dump data to json with postgres you need to use postgres server version >= 9.2'
          end
        end

        private

        def dump_supported?
          Mincer.postgres? && (Mincer.connection.send(:postgresql_version) >= 90200)
        end

        def json_query
          if @options[:root]
            json_query_with_root(@options[:root], @options[:meta])
          else
            basic_json_query
          end
        end

        def base_sql
          @mincer.sql
        end

        # Query for basic json generation. Ex: [{'id': 1}, {...}]
        def basic_json_query(root = 'json', meta = false)
          meta_sql = ''
          if meta
            meta_sql << ", #{@mincer.total_pages} AS total_pages"
            meta_sql << ", #{@mincer.total_count} AS total_count"
            meta_sql << ", #{@mincer.current_page} AS current_page"
            meta_sql << ", #{@mincer.limit_value} AS per_page"
            meta_sql << ", '#{@mincer.sort_attribute}' AS sort_attribute"
            meta_sql << ", '#{@mincer.sort_order}' AS sort_order"
          end
          <<-SQL
            SELECT COALESCE(array_to_json(array_agg(row_to_json(subq))), '[]') AS #{root} #{meta_sql}
            FROM (#{base_sql}) as subq
          SQL
        end

        # Generates json with root. Ex: If root = 'items' resulting json will be { 'items' => [...] }
        # When `meta` passed will add pagination data(Experimental!!!)
        def json_query_with_root(root, meta)
          <<-SQL
            SELECT row_to_json(t) as json FROM ( #{basic_json_query(root, meta)} ) as t
          SQL
        end

      end

      module Options
        extend ActiveSupport::Concern

        def to_json(options = {})
          PgJsonDumper::Processor.new(self, options).to_json
        end
      end

    end
  end
end

::Mincer.add_processor(:pg_json_dumper)
