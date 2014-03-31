require 'spec_helper'
require 'generators/mincer/query_generator'

describe ::Mincer::Generators::QueryGenerator, :type => :generator do
  destination File.expand_path("../../tmp", __FILE__)

  before :each do
    prepare_destination
  end

  it 'should properly create query file' do
    run_generator %w(User)
    assert_file 'app/queries/user_query.rb', /class UserQuery < Mincer::Base/
  end
end
