module Mincer
  module Processors
    module Pagination
      class Processor
        def initialize(mincer)
          @mincer, @args, @relation = mincer, mincer.args, mincer.relation
        end

        def apply
          if self.class.kaminari?
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
          @args[::Mincer.config.pagination.per_page_param_name] || @mincer.class.default_per_page
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
