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
            Mincer.connection.execute(json_query).first['json']
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
            json_query_with_root(@options[:root])
          else
            basic_json_query
          end
        end

        def base_sql
          @mincer.sql
        end

        # Query for basic json generation. Ex: [{'id': 1}, {...}]
        def basic_json_query(root = 'json')
          <<-SQL
            SELECT COALESCE(array_to_json(array_agg(row_to_json(subq))), '[]') AS #{root}
            FROM (#{base_sql}) as subq
          SQL
        end

        # Generates json with root. Ex: If root = 'items' resulting json will be { 'items' => [...] }
        def json_query_with_root(root)
          <<-SQL
            SELECT row_to_json(t) as json FROM ( #{basic_json_query(root)} ) as t
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
