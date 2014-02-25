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

  def self.pg_extension_installed?(extension)
    @installed_extensions ||= {}
    if @installed_extensions[extension.to_sym].nil?
      @installed_extensions[extension.to_sym] = ::Mincer.connection.execute("SELECT DISTINCT p.proname FROM pg_proc p WHERE p.proname = '#{extension}'").count > 0
    end
    @installed_extensions[extension.to_sym]
  end
end


# Loading processors
require 'mincer/processors/sorting/processor'
require 'mincer/processors/pagination/processor'
require 'mincer/processors/pg_search/search_engine'
require 'mincer/processors/pg_search/array_search'
require 'mincer/processors/pg_search/fulltext_search'
require 'mincer/processors/pg_search/trigram_search'
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
