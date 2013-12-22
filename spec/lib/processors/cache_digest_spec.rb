require 'spec_helper'

describe ::Mincer::Processors::CacheDigest do
  context 'when postgres used' do
    before do
      config = YAML.load_file File.expand_path(File.dirname(__FILE__) + '../../../database.yml')
      ActiveRecord::Base.establish_connection config.merge(:adapter => :postgresql)
      ActiveRecord::Base.connection.execute('DROP TABLE IF EXISTS active_record_models')
      ActiveRecord::Base.connection.execute('CREATE TABLE IF NOT EXISTS active_record_models (id SERIAL PRIMARY KEY, text TEXT)')
      class ActiveRecordModel < ActiveRecord::Base
      end
      ActiveRecordModel.create!(text: 'Test1')
      ActiveRecordModel.create!(text: 'Test2')
    end

    describe 'digesting any basic model without any Mincer::Base configuration' do
      subject(:model) do
        Class.new(Mincer::Base) do
          digest! 'text'
        end
      end

      it 'dumps data via postgres' do
        query = subject.new(ActiveRecordModel)
        digest = query.digest
        digest.should be_a(String)
        digest.should == '\xe2ffe3413a3d5ee8752a89c0e7a37270'
      end
    end
  end


  context 'when postgres used' do

  end

end
