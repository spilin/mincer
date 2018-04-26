module Mincer
  module Processors
    module Pagination
      class Processor
        def initialize(mincer)
          @mincer, @args, @relation = mincer, mincer.args, mincer.relation
        end

        def apply
          if defined?(::Chewy) && @mincer.respond_to?(:chewy_search)
            @relation
          elsif @mincer.respond_to?(:elastic_search)
            @relation
          elsif self.class.kaminari?
            @relation.page(page).per(per_page)
          elsif self.class.will_paginate?
            @relation.paginate(page: page, per_page: per_page)
          else
            warn 'To enable pagination please add kaminari or will_paginate to your Gemfile'
            @relation
          end
        end

        def self.kaminari?
          defined?(::Kaminari)
        end

        def self.will_paginate?
          defined?(::WillPaginate)
        end

        def page
          @args[::Mincer.config.pagination.page_param_name]
        end

        def per_page
          @mincer.class.default_per_page || @args[::Mincer.config.pagination.per_page_param_name]
        end
      end

      module Options
        extend ActiveSupport::Concern

        module ClassMethods
          def skip_pagination!
            active_processors.delete(Mincer::Processors::Pagination::Processor)
          end

          def paginate_defaults(options = {})
            @default_per_page = options[:per_page] if options[:per_page]
          end

          def default_per_page
            @default_per_page
          end
        end

        def total_pages
          delegate_pagination(:total_pages)
        end

        def current_page
          delegate_pagination(:current_page)
        end

        def limit_value
          delegate_pagination(:limit_value)
        end

        def delegate_pagination(method)
          if self.respond_to?(:chewy_search_result) && self.chewy_search_result
            self.chewy_search_result.send(method)
          elsif self.respond_to?(:elastic_search_result) && self.respond_to?(:"elastic_#{method}")
            self.send(:"elastic_#{method}")
          else
            @relation.send(method)
          end
        end
      end

      class Configuration
        include ActiveSupport::Configurable

        config_accessor :page_param_name do
          (::Mincer::Processors::Pagination::Processor.kaminari? && ::Kaminari.config.param_name) || :page
        end

        config_accessor :per_page_param_name do
          :per_page
        end
      end
    end
  end
end


::Mincer.add_processor(:pagination)
