module Mincer
  module Processors

    class Sort
      def initialize(mincer)
        @mincer, @args, @relation = mincer, mincer.args, mincer.relation
      end

      def apply
        relation = @relation.order("#{sort_attr} #{order_attr}")
        @mincer.sort_attribute, @mincer.sort_order = relation.try(:order_values).try(:first).try(:split)
        relation
      end

      def sort_attr
        (@mincer.allowed_sort_attributes.include?(@args['sort']) && @args['sort']) || @mincer.send(:default_sort_attribute)
      end

      def order_attr
        (%w{ASC DESC}.include?(@args['order']) && @args['order']) || @mincer.default_sort_order
      end
    end


    module SortOptions
      extend ActiveSupport::Concern

      included do
        attr_accessor :sort_attribute, :sort_order
      end

      module ClassMethods
        def skip_sorting!
          active_processors.delete(Mincer::Processors::Sort)
        end
      end

      # Default sort attribute. You must override this method if you want something else
      def default_sort_attribute
        'id'
      end

      # Default order attribute. You must override this method if you want something else
      def default_sort_order
        'ASC'
      end

      # Allowed sort attributes, should return array of strings
      def allowed_sort_attributes
        @scope.attribute_names
      end
    end

  end
end