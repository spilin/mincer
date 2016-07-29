module Mincer
  module ActionView
    module SortHelper
      # Returns sorting URL for collection and attribute
      #
      # <tt>collection</tt> - instance of QueryObject
      # <tt>attribute</tt> - Attribute that will be used to sort table
      def sort_url_for(collection, attribute, permitted_params = params)
        url_for(permitted_params.merge(:sort => attribute, :order => opposite_order_for(collection, attribute)))
      end

      def opposite_order_for(collection, attribute)
        return nil unless collection.sort_attribute == attribute.to_s
        if collection.sort_order.to_s.downcase == 'asc'
          'desc'
        elsif collection.sort_order.to_s.downcase == 'desc'
          'asc'
        else
          'asc'
        end
      end


      # Returns chevron class, if attribute is the one that was used for sorting
      #
      # <tt>collection</tt> - instance of QueryObject
      # <tt>attribute</tt> - Attribute that will be used to sort table
      def sort_class_for(collection, attribute)
        return nil unless collection.sort_attribute == attribute.to_s
        if collection.sort_order.downcase == 'asc'
          ::Mincer.config.sorting.asc_class
        elsif collection.sort_order.downcase == 'desc'
          ::Mincer.config.sorting.desc_class
        else
          ''
        end
      end

    end
  end
end
