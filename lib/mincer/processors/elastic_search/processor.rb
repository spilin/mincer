# This and all processors are heavily influenced by elastic_search(https://github.com/Casecommons/elastic_search)
module Mincer
  module Processors
    module ElasticSearch
      class Processor
        include ::Mincer::Processors::Helpers

        def initialize(mincer)
          @mincer, @args, @relation = mincer, mincer.args, mincer.relation
        end

        def apply
          if @mincer.respond_to?(:elastic_search)
            elastic_search_query = @mincer.elastic_search(@relation, @args)
            @mincer.elastic_search_result = if paginate?(elastic_search_query)
              @mincer.elastic_current_page = (page.presence || 1).to_i
              @mincer.elastic_limit_value = per_page.to_i
              from = @mincer.elastic_current_page * per_page - per_page
              elastic_search_query.search(elastic_search_query.payload.merge(size: @mincer.elastic_limit_value, from: from))
            else
              elastic_search_query.search(elastic_search_query.payload)
            end
            @mincer.elastic_total_pages = @mincer.elastic_search_result.response['hits']['total']
            ids = (@mincer.elastic_search_result.response['hits'].try(:[], 'hits') || []).to_a.map { |e| e['_id'].to_i }
            table_name = @relation.class.respond_to?(:table_name) ? @relation.class.table_name : @relation.model.table_name
            @relation = @relation.where(id: ids).reorder("array_position(ARRAY#{ids}::integer[], #{table_name}.id)")
          end
          @relation
        end

        def params
          Array.wrap(@mincer.send(:elastic_search_params))
        end

        def options
          @mincer.send(:elastic_search_options)
        end

        # Ugly!!! and dup from pagination processor
        def page
          @args[::Mincer.config.pagination.page_param_name]
        end

        def per_page
          @mincer.class.default_per_page || @args[::Mincer.config.pagination.per_page_param_name]
        end

        def paginate?(elastic_search_query)
          return false unless ::Mincer.processors.include?(Mincer::Processors::Pagination::Processor)
          true
        end
      end

      module Options
        extend ActiveSupport::Concern
        attr_accessor :elastic_search_result, :elastic_total_pages, :elastic_current_page, :elastic_limit_value

        module ClassMethods
          def elastic_search(&block)
            @elastic_search = block
          end

          def elastic_search
            @elastic_search
          end
        end

        def elastic_search_params
          @elastic_search_params ||= {}
        end

        def elastic_search_options
          @elastic_search_options ||= {}
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

::Mincer.add_processor(:elastic_search)
