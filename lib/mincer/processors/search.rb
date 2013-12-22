module Mincer
  module Processors
    class Search
      def initialize(mincer)
        @mincer, @args, @relation = mincer, mincer.args, mincer.relation
      end

      def apply
        if Mincer.postgres? && !textacular?
          warn 'You must include "textacular" to  your Gemfile to use search'
          @relation
        elsif Mincer.postgres? && @args['pattern']
          @relation.basic_search(@args['pattern']).presence || @relation.fuzzy_search(@args['pattern'])
        else
          @relation
        end
      end

      def textacular?
        defined?(::Textacular)
      end
    end

    module SearchOptions
      extend ActiveSupport::Concern

      module ClassMethods
        def skip_search!
          active_processors.delete(Mincer::Processors::Search)
        end
      end
    end
  end
end