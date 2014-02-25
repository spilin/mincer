require 'spec_helper'

describe ::Mincer::Processors::PgSearch::Processor do
  context 'when postgres used' do
    before do
      setup_postgres_table
      class ActiveRecordModel < ActiveRecord::Base
      end
      ActiveRecordModel.reset_column_information
      ActiveRecordModel.create!(text: 'Test')
      ActiveRecordModel.create!(text: 'Bingo')
      ActiveRecordModel.create!(text: 'Bongo')
    end

    describe 'searching' do
      describe 'searches with basic model without any Mincer::Base configuration' do
        subject(:model) do
          Class.new(Mincer::Base)
        end

        describe 'searching with t_search' do
          it 'searches by pattern in args' do
            query = subject.new(ActiveRecordModel, { 'pattern' => 'Bingo' })
            query.to_a.count.should eq(1)
          end

          it 'avoids search when pattern is an empty string or spaces' do
            query = subject.new(ActiveRecordModel, { 'pattern' => ' ' })
            query.to_a.count.should eq(3)
          end

          context 'when another search_column exists with nil value on a found item' do
            before do
              setup_postgres_table([['id', 'SERIAL PRIMARY KEY'], ['text', 'TEXT'], ['text2', 'TEXT']])
              class ActiveRecordModel < ActiveRecord::Base
              end
              ActiveRecordModel.reset_column_information
              ActiveRecordModel.create!(text: 'Test')
              ActiveRecordModel.create!(text: 'Bingo')
            end

            it 'still includes found item in results' do
              query = subject.new(ActiveRecordModel, { 'pattern' => 'Bingo' })
              warn query.to_sql
              query.to_a.count.should eq(1)
            end
          end
        end
      end


      describe 'searching when basic model has disabled search' do
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
