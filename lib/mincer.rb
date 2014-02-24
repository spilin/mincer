require 'mincer/version'


require 'mincer/base'

module Mincer
  def self.processors
    @processors ||= []
  end

  def self.postgres?
    self.connection.is_a?(::ActiveRecord::ConnectionAdapters::PostgreSQLAdapter) rescue false
  end

  def self.connection
    ::ActiveRecord::Base.connection()
  end

  def self.add_processor(processor)
    processor_scope = ::Mincer::Processors.const_get(processor.to_s.camelize)
    ::Mincer.processors << processor_scope.const_get('Processor')
    ::Mincer::Base.send(:include, processor_scope.const_get('Options'))
  end
end


# Loading processors
require 'mincer/processors/sorting/processor'
require 'mincer/processors/pagination/processor'
require 'mincer/processors/pg_search/t_search'
require 'mincer/processors/pg_search/processor'
require 'mincer/processors/cache_digest/processor'
require 'mincer/processors/pg_json_dumper/processor'

# Loading ActionView helpers
if defined?(ActionView)
  require 'mincer/action_view/sort_helper'
  ::Mincer::ActionView.constants.each do |k|
    klass = ::Mincer::ActionView.const_get(k)
    ActionView::Base.send(:include, klass) if klass.is_a?(Module)
  end
end


#if defined?(::Rails)
#  module Mincer
#    class Railtie < ::Rails::Railtie
#      initializer 'mincer.setup_paths' do
#      end
#
#      initializer 'carrierwave.active_record' do
#        #ActiveSupport.on_load :active_record do
#        #  require 'carrierwave/orm/activerecord'
#        #end
#      end
#    end
#  end
#end
