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
end


# Loading processors
require 'mincer/processors/sort'
require 'mincer/processors/paginate'
require 'mincer/processors/search'
require 'mincer/processors/cache_digest'
require 'mincer/processors/pg_json_dumper'
::Mincer::Processors.constants.each do |k|
  klass = ::Mincer::Processors.const_get(k)
  if klass.is_a?(Class)
    ::Mincer.processors << klass
  elsif klass.is_a?(Module)
    ::Mincer::Base.send(:include, klass)
  end
end


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
