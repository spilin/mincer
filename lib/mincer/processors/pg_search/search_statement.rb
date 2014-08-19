module Mincer
  module Processors
    module PgSearch
      class SearchStatement
        attr_accessor :columns, :options, :pattern
        alias_method :terms, :pattern

        def initialize(columns, options = {})
          @columns, @options = columns, ::ActiveSupport::HashWithIndifferentAccess.new(options)
        end

        def sanitizers(type = :all)
          @sanitizers ||= {}
          @sanitizers[type] ||= Sanitizer::AVAILABLE_SANITIZERS.select do |sanitizer|
            options[sanitizer].is_a?(Hash) && [:query, :document].include?(type) ? options[sanitizer][type] : options[sanitizer]
          end
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

      end
    end
  end
end
