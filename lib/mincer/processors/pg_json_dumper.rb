module Mincer
  module Processors
    class PgJsonDumper

      def initialize(mincer, options = {})
        @mincer, @args, @relation, @options = mincer, mincer.args, mincer.relation, options
      end

      def apply
        @relation
      end

      def to_json
        if dump_supported?
          Mincer.connection.execute(@options[:root] ? query_with_root(@options[:root]) : query).first['json']
        else
          warn 'To dump data to json with postgres you need to use postgres server version >= 9.2'
        end
      end

      private

      def dump_supported?
        Mincer.postgres? && (Mincer.connection.send(:postgresql_version) >= 90200)
      end

      def query(root = 'json')
        <<-SQL
          SELECT COALESCE(array_to_json(array_agg(row_to_json(subq))), '[]') AS #{root}
          FROM (#{@mincer.sql}) as subq
        SQL
      end

      def query_with_root(root)
        <<-SQL
          SELECT row_to_json(t) as json FROM ( #{query(root)} ) as t
        SQL
      end

    end

    module PgJsonDumperOptions
      extend ActiveSupport::Concern

      def to_json(options = {})
        PgJsonDumper.new(self, options).to_json
      end
    end

  end
end
