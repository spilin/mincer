module Mincer
  module Processors
    module PgSearch
      class SearchStatement
        attr_accessor :columns, :options

        def initialize(columns, options = {})
          @columns, @options = columns, options
        end

        def sanitizers
          @sanitizers ||= Sanitizer::AVAILABLE_SANITIZERS.select {|sanitizer| options[sanitizer] }
        end

        def dictionary
          options[:dictionary] || Mincer.config.pg_search.fulltext_engine[:dictionary]
        end

        def threshold
          options[:threshold] || Mincer.config.pg_search.trigram_engine[:threshold]
        end

      end
    end
  end
end
