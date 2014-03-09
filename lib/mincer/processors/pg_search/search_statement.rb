module Mincer
  module Processors
    module PgSearch
      class SearchStatement
        attr_accessor :columns, :options, :pattern
        alias_method :terms, :pattern

        def initialize(columns, options = {})
          @columns, @options = columns, ::ActiveSupport::HashWithIndifferentAccess.new(options)
        end

        def sanitizers
          @sanitizers ||= Sanitizer::AVAILABLE_SANITIZERS.select { |sanitizer| options[sanitizer] }
        end

        def dictionary
          options[:dictionary] || Mincer.config.pg_search.fulltext_engine[:dictionary]
        end

        def threshold
          options[:threshold] || Mincer.config.pg_search.trigram_engine[:threshold]
        end

        def param_name
          options[:param_name] || Mincer.config.pg_search.param_name
        end

        def extract_pattern_from(args)
          @pattern = args[param_name]
        end

        def pattern_present?
          @pattern.try(:present?) || @pattern.try(:any?)
        end

      end
    end
  end
end
