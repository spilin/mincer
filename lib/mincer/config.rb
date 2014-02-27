# This should be extracted and moved to gem
module Mincer
  class Config
    attr_reader :pg_search

    def pg_search
      @pg_search = {  }
    end

  end
end

