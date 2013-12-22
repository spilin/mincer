module Mincer
  module Processors
    class CacheDigest

      def initialize(mincer)
        @mincer, @args, @relation = mincer, mincer.args, mincer.relation
      end

      def apply
        @relation
      end

      def digest
        Mincer.connection.execute(digest_sql).first.values.first
      end

      private

      def digest_sql
        <<-SQL
          SELECT digest(#{digest_columns_as_sql}, 'md5') as digest
          FROM (#{@relation.connection.unprepared_statement { @relation.to_sql }}) as digest_q
        SQL
      end

      def digest_columns_as_sql
        @mincer.class.digest_columns.map { |column| "string_agg(digest_q.#{column}::text, '')" }.join(' || ')
      end

    end

    module CacheDigestOptions
      extend ActiveSupport::Concern

      def digest
        CacheDigest.new(self).digest
      end

      module ClassMethods
        def digest!(*digest_columns)
          @digest_columns = digest_columns
        end

        def digest_columns
          @digest_columns || []
        end
      end
    end
  end
end
