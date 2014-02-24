require 'spec_helper'

describe ::Mincer::Processors::PgSearch::Processor do
  context 'when postgres used' do
    before do
      setup_basic_postgres_table
      class ActiveRecordModel < ActiveRecord::Base
      end
      ActiveRecordModel.create!(text: 'Test')
      ActiveRecordModel.create!(text: 'Bingo')
      ActiveRecordModel.create!(text: 'Bongo')
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

        it 'avoids search when pattern is an empty string or spaces' do
          query = subject.new(ActiveRecordModel, { 'pattern' => ' ' })
          query.to_a.count.should eq(3)
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
      setup_basic_sqlite3_table
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
