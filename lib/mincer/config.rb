# This should be extracted and moved to gem
module Mincer

  def self.configure
    yield(config)
  end

  def self.config
    @config ||= ::Mincer::Configuration.new
  end

  class Configuration

    def add(processor, config_class)
      define_config_accessors(processor, config_class)
    end

    def define_config_accessors(processor, config_class)
      class_eval <<-ACCESORS, __FILE__
        def #{processor}
          @#{processor} ||= #{config_class}.new
          block_given? ? yield(@#{processor}) : @#{processor}
        end
      ACCESORS
    end

  end
end

