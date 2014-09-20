require 'rails/generators'

module Mincer
  module Generators
    class QueryGenerator < ::Rails::Generators::NamedBase
      source_root File.expand_path("../templates", __FILE__)

      desc <<DESC
  Description:
      Creates query file for selected model
DESC

      def create_query_file
        template 'query.rb', "app/queries/#{file_name}_query.rb"
      end
    end
  end
end
