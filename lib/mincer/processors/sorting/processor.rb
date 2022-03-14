module Mincer
  module Processors
    module Sorting
      class Processor
        def initialize(mincer)
          @mincer, @args, @relation = mincer, mincer.args, mincer.relation
        end

        def apply
          sorting_string = sort_string
          if sorting_string.present?
            @mincer.sort_attribute = (sort_attr || default_sort).to_s
            @mincer.sort_order = (order_attr || default_order).to_s
            @mincer.default_sorting = sort_attr.blank? && order_attr.blank?
            @relation.order(sorting_string)
          else
            @relation
          end
        end

        def sort_string
          Arel.sql([(sort_attr || default_sort), (order_attr || default_order)].compact.uniq.join(' '))
        end

        def sort_attr
          (@mincer.send(:allowed_sort_attributes).include?(sort) && sort)
        end

        def order_attr
          (%w{asc desc}.include?(order.try(:downcase)) && order)
        end

        def sort
          @args[::Mincer.config.sorting.sort_param_name]
        end

        def default_sort
          @mincer.try(:default_sort_attribute)
        end

        def order
          @args[::Mincer.config.sorting.order_param_name]
        end

        def default_order
          @mincer.try(:default_sort_order)
        end

      end


      module Options
        extend ActiveSupport::Concern

        included do
          # Used in view helpers
          attr_accessor :sort_attribute, :sort_order, :default_sorting
        end

        module ClassMethods
          def skip_sorting!
            active_processors.delete(Mincer::Processors::Sorting::Processor)
          end
        end

        # Default sort attribute. You must override this method if you want something else
        def default_sort_attribute
          ::Mincer.config.sorting.sort_attribute
        end

        # Default order attribute. You must override this method if you want something else
        def default_sort_order
          ::Mincer.config.sorting.order_attribute
        end

        # Allowed sort attributes, should return array of strings
        def allowed_sort_attributes
          @scope.attribute_names
        end
      end

      class Configuration
        include ActiveSupport::Configurable

        config_accessor :sort_param_name do
          :sort
        end

        config_accessor :sort_attribute do
          :id
        end

        config_accessor :order_param_name do
          :order
        end

        config_accessor :order_attribute do
          :asc
        end

        config_accessor :asc_class do
          'sorted order_down'
        end

        config_accessor :desc_class do
          'sorted order_up'
        end

      end

    end
  end
end

::Mincer.add_processor(:sorting)
