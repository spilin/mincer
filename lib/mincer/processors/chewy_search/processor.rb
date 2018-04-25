# This and all processors are heavily influenced by chewy_search(https://github.com/Casecommons/chewy_search)
module Mincer
  module Processors
    module ChewySearch
      class Processor
        include ::Mincer::Processors::Helpers

        def initialize(mincer)
          @mincer, @args, @relation = mincer, mincer.args, mincer.relation
        end

        def apply
          if defined?(::Chewy) && @mincer.respond_to?(:chewy_search)
            chewy_search_query = @mincer.chewy_search(@relation, @args)
            if paginate?(chewy_search_query)
              chewy_search_query = chewy_search_query.per(per_page).page(page)
            end
            @mincer.chewy_search_result = chewy_search_query
            ids = @mincer.chewy_search_result.to_a.map {|e| e.attributes['id']}
            table_name = @relation.class.respond_to?(:table_name) ? @relation.class.table_name : @relation.model.table_name
            @relation = @relation.where(id: ids).reorder("array_position(ARRAY#{ids}::integer[], #{table_name}.id)")
          end
          @relation
        end

        def params
          Array.wrap(@mincer.send(:chewy_search_params))
        end

        def options
          @mincer.send(:chewy_search_options)
        end

        # Ugly!!! and dup from pagination processor
        def page
          @args[::Mincer.config.pagination.page_param_name]
        end

        def per_page
          @mincer.class.default_per_page || @args[::Mincer.config.pagination.per_page_param_name]
        end

        def paginate?(chewy_search_query)
          return false unless ::Mincer.processors.include?(Mincer::Processors::Pagination::Processor)
          return false unless chewy_search_query.respond_to?(:per) && chewy_search_query.respond_to?(:page)
          true
        end
      end

      module Options
        extend ActiveSupport::Concern
        attr_accessor :chewy_search_result

        module ClassMethods
          def chewy_search(&block)
            @chewy_search = block
          end

          def chewy_search
            @chewy_search
          end
        end

        def chewy_search_params
          @chewy_search_params ||= {}
        end

        def chewy_search_options
          @chewy_search_options ||= {}
        end
      end

      class Configuration
        include ActiveSupport::Configurable
        config_accessor :param_name do
          'pattern'
        end
      end

    end
  end
end

::Mincer.add_processor(:chewy_search)
