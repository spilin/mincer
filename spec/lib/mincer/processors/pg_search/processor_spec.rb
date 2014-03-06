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

    describe 'config' do
      it 'defines method with pg_options' do
        subject = Class.new(Mincer::Base) do
          pg_search [{ columns: %w{"active_record_models"."tags" }, engines: [:array] }]
        end
        query = subject.new(ActiveRecordModel)
        query.send(:pg_search_options).should == [{ columns: %w{"active_record_models"."tags" }, engines: [:array] }]
      end
    end

    describe 'searching' do
      describe 'searches with basic model without any Mincer::Base configuration' do
        subject(:model) do
          Class.new(Mincer::Base)
        end

        describe 'searching with fulltext search' do
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
              query.to_a.count.should eq(1)
            end
          end


          describe 'searching with array' do
            before do
              setup_postgres_table([['id', 'SERIAL PRIMARY KEY'], ['text', 'TEXT'], ['tags', 'TEXT[]']])
              class ActiveRecordModel < ActiveRecord::Base
              end
              ActiveRecordModel.reset_column_information
              ActiveRecordModel.create!(text: 'Test', tags: ['a', 'b'])
              ActiveRecordModel.create!(text: 'Bingo', tags: ['b', 'c'])
            end

            it 'includes 2 items when both items include pattern' do
              subject = Class.new(Mincer::Base) do
                pg_search [{ :columns => %w{"active_record_models"."tags" }, engines: [:array] }]
              end
              query = subject.new(ActiveRecordModel, { 'pattern' => 'b' })
              query.to_a.count.should eq(2)
            end

            it 'includes 1 item when match was found on one item' do
              subject = Class.new(Mincer::Base) do
                pg_search [{ :columns => %w{"active_record_models"."tags" }, engines: [:array] }]
              end
              query = subject.new(ActiveRecordModel, { 'pattern' => 'c' })
              query.to_a.count.should eq(1)
            end

            it 'includes both when matched with array overlap and option "any_word" set to true' do
              subject = Class.new(Mincer::Base) do
                pg_search [{ :columns => %w{"active_record_models"."tags" }, engines: [:array], any_word: true }]
              end
              query = subject.new(ActiveRecordModel, { 'pattern' => 'a c d' })
              query.to_a.count.should eq(2)
            end

            it 'includes both when matched with array overlap and option "any_word" set to true(separated with ",")' do
              subject = Class.new(Mincer::Base) do
                def pg_search_options
                  [{ :columns => %w{"active_record_models"."tags"}, engines: [:array], any_word: true }]
                end
              end
              query = subject.new(ActiveRecordModel, { 'pattern' => 'a, c,d' })
              query.to_a.count.should eq(2)
            end

            it 'includes no items when nothing matched pattern' do
              subject = Class.new(Mincer::Base) do
                def pg_search_options
                  [{ :columns => %w{"active_record_models"."tags" }, engines: [:array] }]
                end
              end
              query = subject.new(ActiveRecordModel, { 'pattern' => 'd e' })
              query.to_a.count.should eq(0)
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
