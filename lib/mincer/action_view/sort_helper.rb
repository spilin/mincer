module Mincer
  module ActionView
    module SortHelper
      # Returns sorting URL for collection and attribute
      #
      # <tt>collection</tt> - instance of QueryObject
      # <tt>attribute</tt> - Attribute that will be used to sort table
      def sort_url_for(collection, attribute)
        url_for(params.merge(:sort => attribute, :order => opposite_order_for(collection, attribute)))
      end

      def opposite_order_for(collection, attribute)
        return nil unless collection.sort_attribute == attribute.to_s
        if collection.sort_order.to_s.upcase == 'ASC'
          'DESC'
        elsif collection.sort_order.to_s.upcase == 'DESC'
          'ASC'
        else
          'ASC'
        end
      end


      # Returns chevron class, if attribute is the one that was used for sorting
      #
      # <tt>collection</tt> - instance of QueryObject
      # <tt>attribute</tt> - Attribute that will be used to sort table
      def sort_class_for(collection, attribute)
        return nil unless collection.sort_attribute == attribute.to_s
        if collection.sort_order.upcase == 'ASC'
          'sorted order_down'
        elsif collection.sort_order.upcase == 'DESC'
          'sorted order_up'
        else
          ''
        end
      end

    end
  end
end
