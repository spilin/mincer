require 'spec_helper'

describe ::Mincer::Processors::Search do
  context 'when postgres used' do
    before do
      config = YAML.load_file File.expand_path(File.dirname(__FILE__) + '../../../database.yml')
      ActiveRecord::Base.establish_connection config.merge(:adapter => :postgresql)
      ActiveRecord::Base.connection.execute('DROP TABLE IF EXISTS active_record_models')
      ActiveRecord::Base.connection.execute('CREATE TABLE IF NOT EXISTS active_record_models (id SERIAL PRIMARY KEY, text TEXT)')
      class ActiveRecordModel < ActiveRecord::Base
      end
      ActiveRecordModel.create!(text: 'Test')
      ActiveRecordModel.create!(text: 'Bingo')
      ActiveRecordModel.create!(text: 'Bongo')
    end

    describe 'search without "textacular"' do
      subject(:model) do
        Class.new(Mincer::Base)
      end

      it 'searches by pattern in args' do
        ::Mincer::Processors::Search.any_instance.stub(:textacular?).and_return(false)
        query = subject.new(ActiveRecordModel, { 'pattern' => 'Bingo' })
        query.to_a.count.should eq(3)
      end
    end

    describe 'search with "textacular"' do
      describe 'searches with basic model without any Mincer::Base configuration' do
        subject(:model) do
          Class.new(Mincer::Base)
        end

        it 'searches by pattern in args' do
          query = subject.new(ActiveRecordModel, { 'pattern' => 'Bingo' })
          query.to_a.count.should eq(1)
        end
      end


      describe 'paginating when basic model has disabled pagination' do
        it 'does not modifies relation' do
          subject = Class.new(Mincer::Base) do
            skip_search!
          end
          query = subject.new(ActiveRecordModel, { 'pattern' => 'Bingo' })
          query.to_a.count.should eq(3)
        end
      end
    end
  end

  context 'when postgres is NOT used' do
    before do
      ActiveRecord::Base.establish_connection(:adapter => 'sqlite3', :database => ':memory:')
      ActiveRecord::Base.connection.execute('CREATE TABLE active_record_models (id INTEGER UNIQUE, text STRING)')
      class ActiveRecordModel < ActiveRecord::Base
      end
      ActiveRecordModel.create!(text: 'Test')
      ActiveRecordModel.create!(text: 'Bingo')
      ActiveRecordModel.create!(text: 'Bongo')
    end

    subject(:model) do
      Class.new(Mincer::Base)
    end

    it 'returns all records' do
      query = subject.new(ActiveRecordModel, { 'pattern' => 'Bingo' })
      query.to_a.count.should eq(3)
    end
  end


end
