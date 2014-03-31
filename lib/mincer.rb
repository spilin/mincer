require 'ostruct'
require 'mincer/version'
require 'mincer/core_ext/string'
require 'mincer/config'
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
    processor_scope = ::Mincer::Processors.const_get(ActiveSupport::Inflector.camelize(processor.to_s, true))
    ::Mincer.processors << processor_scope.const_get('Processor')
    ::Mincer::Base.send(:include, processor_scope.const_get('Options')) if processor_scope.const_defined?('Options')
    ::Mincer.config.add(processor, processor_scope.const_get('Configuration'))  if processor_scope.const_defined?('Configuration') if processor_scope.const_defined?('Configuration')
  end

  def self.pg_extension_installed?(extension)
    @installed_extensions ||= {}
    if @installed_extensions[extension.to_sym].nil?
      @installed_extensions[extension.to_sym] = ::Mincer.connection.execute("SELECT DISTINCT p.proname FROM pg_proc p WHERE p.proname = '#{extension}'").count > 0
    end
    @installed_extensions[extension.to_sym]
  end

end

# Loading helpers
require 'mincer/processors/helpers'

# Loading processors
require 'mincer/processors/sorting/processor'
require 'mincer/processors/pagination/processor'
require 'mincer/processors/pg_search/search_statement'
require 'mincer/processors/pg_search/sanitizer'
require 'mincer/processors/pg_search/search_engines/base'
require 'mincer/processors/pg_search/search_engines/array'
require 'mincer/processors/pg_search/search_engines/fulltext'
require 'mincer/processors/pg_search/search_engines/trigram'
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
