module Mincer
  module Processors
    module Sorting
      class Processor
        def initialize(mincer)
          @mincer, @args, @relation = mincer, mincer.args, mincer.relation
        end

        def apply
          relation = @relation.order(sort_string)
          @mincer.sort_attribute, @mincer.sort_order = sort_attr, order_attr
          relation
        end

        def sort_string
          sort_attr ? "#{sort_attr} #{order_attr}, #{@mincer.send(:default_sort_attribute)}" : "#{@mincer.send(:default_sort_attribute)} #{order_attr}"
        end

        def sort_attr
          @mincer.send(:allowed_sort_attributes).include?(@args['sort']) && @args['sort']
        end

        def order_attr
          (%w{ASC DESC}.include?(@args['order']) && @args['order']) || @mincer.send(:default_sort_order)
        end
      end


      module Options
        extend ActiveSupport::Concern

        included do
          attr_accessor :sort_attribute, :sort_order
        end

        module ClassMethods
          def skip_sorting!
            active_processors.delete(Mincer::Processors::Sorting::Processor)
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
end

::Mincer.add_processor(:sorting)
