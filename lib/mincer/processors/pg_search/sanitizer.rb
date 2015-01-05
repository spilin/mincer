module Mincer
  module Processors
    module PgSearch
      class Sanitizer
        AVAILABLE_SANITIZERS = [:coalesce, :ignore_case, :ignore_accent]
        attr_accessor :term, :sanitizers

        def initialize(term, *sanitizers)
          @term, @sanitizers = term, AVAILABLE_SANITIZERS & Array.wrap(sanitizers).flatten
        end

        def sanitize_column
          @sanitized_column ||= sanitize(Arel.sql(@term))
        end

        def sanitize_string(options = {})
          if sanitizers.empty?
            if defined?(Arel::Nodes::Quoted)
              return self.class.quote(@term)
            elsif options[:quote]
              return Mincer.connection.quote(@term)
            end
          end
          @sanitized_string ||= sanitize(@term)
        end

        def sanitize(node)
          sanitizers.inject(node) do |query, sanitizer|
            query = self.class.send(sanitizer, query)
            query
          end
        end

        def self.sanitize_column(term, *sanitizers)
          new(term, *sanitizers).sanitize_column
        end

        def self.sanitize_string(term, *sanitizers)
          new(term, *sanitizers).sanitize_string
        end

        def self.sanitize_string_quoted(term, *sanitizers)
          new(term, *sanitizers).sanitize_string(quote: true)
        end

        def self.ignore_case(term)
          Arel::Nodes::NamedFunction.new('lower', [quote(term)])
        end

        def self.ignore_accent(term)
          Arel::Nodes::NamedFunction.new('unaccent', [quote(term)])
        end

        def self.coalesce(term, val = '')
          if Mincer.pg_extension_installed?(:unaccent)
            Arel::Nodes::NamedFunction.new('coalesce', [quote(term), quote(val)])
          else
            term
          end
        end

        def self.quote(string)
          if defined?(Arel::Nodes::Quoted) && !string.is_a?(Arel::Nodes::Quoted) && !string.is_a?(Arel::Nodes::NamedFunction)
            Arel::Nodes::Quoted.new(string)
          else
            string
          end
        end

      end
    end
  end
end
