require 'spec_helper'

describe ::Mincer::Processors::PgJsonDumper do
  context 'when postgres is used' do
    before do
      setup_basic_postgres_table
      class ActiveRecordModel < ActiveRecord::Base
      end
      ActiveRecordModel.create!(text: 'Test1')
      ActiveRecordModel.create!(text: 'Test2')
    end

    describe 'dumping to json with basic model without any Mincer::Base configuration' do
      subject(:model) do
        Class.new(Mincer::Base)
      end

      it 'dumps data via postgres' do
        query = subject.new(ActiveRecordModel)
        ActiveRecord::Base.connection.should_receive(:execute).and_call_original
        json_string = query.to_json
        json_string.should be_a(String)
        json_hash = JSON.parse(json_string)
        json_hash.size.should eq(2)
        json_hash[0]['id'].should == 1
        json_hash[0]['text'].should == 'Test1'
        json_hash[1]['id'].should == 2
        json_hash[1]['text'].should == 'Test2'
      end

      context 'when root option is passed' do
        it 'puts responce inside under root key' do
          query = subject.new(ActiveRecordModel)
          ActiveRecord::Base.connection.should_receive(:execute).and_call_original
          json_string = query.to_json(root: 'items')
          json_string.should be_a(String)
          json_hash = JSON.parse(json_string)
          json_hash['items'].size.should eq(2)
          json_hash['items'][0]['id'].should == 1
          json_hash['items'][0]['text'].should == 'Test1'
          json_hash['items'][1]['id'].should == 2
          json_hash['items'][1]['text'].should == 'Test2'
        end
      end

    end
  end
  context 'when postgres is NOT used' do
    before do
      setup_basic_sqlite3_table
      class ActiveRecordModel < ActiveRecord::Base
      end
      ActiveRecordModel.create!(id: 1, text: 'Test1')
      ActiveRecordModel.create!(id: 2, text: 'Test2')
    end

    subject(:model) do
      Class.new(Mincer::Base)
    end

    it 'dumps data via calling super' do
      query = subject.new(ActiveRecordModel)
      ActiveRecord::Base.connection.should_not_receive(:execute)
      json_string = query.to_json
      json_string.should be_nil
    end
  end

end
