module Mincer

  def self.version
    Gem::Version.new '0.1.1'
  end

  module VERSION #:nodoc:
    MAJOR, MINOR, TINY, PRE = Mincer.version.segments
    STRING = Mincer.version.to_s
  end
end







