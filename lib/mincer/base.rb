# This should be extracted and moved to gem
module Mincer
  class Base
    include Enumerable

    attr_accessor :args, :sql, :relation

    # Builds query object
    def initialize(scope, args = {})
      @args = if defined?(ActionController::Parameters) && args.is_a?(ActionController::Parameters) && args.respond_to?(:to_unsafe_h)
        ::ActiveSupport::HashWithIndifferentAccess.new(args.to_unsafe_h)
      else
        ::ActiveSupport::HashWithIndifferentAccess.new(args)
      end
      @scope, @relation = scope, build_query(scope, @args)
      execute_processors
    end

    def execute_processors
      self.class.active_processors.each {|processor| @relation = processor.new(self).apply }
    end

    def self.active_processors
      @processors ||= Mincer.processors.clone
    end

    # Grabs relation raw sql
    def sql
      @sql ||= @relation.connection.unprepared_statement { @relation.to_sql }
    end

    # Allows enumerable methods to be called directly on object
    def each(&block)
      @collection ||= if @relation.is_a?(ActiveRecord::Relation)
        @relation.to_a
      else
        @relation.all
      end
      @collection.each(&block)
    end

    # Must be implemented in any subclass
    def build_query(relation, args)
      relation
    end

    # Pass methods to relation object
    def method_missing(method_id, *params)
      @relation.send(method_id, *params)
    end

  end
end
