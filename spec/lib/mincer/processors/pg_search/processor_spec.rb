require 'spec_helper'

describe ::Mincer::Processors::PgSearch::Processor do
  context 'when postgres used' do
    before do
      setup_postgres_table
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
        query.send(:pg_search_params).should == [{ columns: %w{"active_record_models"."tags" }, engines: [:array] }]
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
              ActiveRecordModel.create!(text: 'Test')
              ActiveRecordModel.create!(text: 'Bingo')
            end

            it 'still includes found item in results' do
              query = subject.new(ActiveRecordModel, { 'pattern' => 'Bingo' })
              query.to_a.count.should eq(1)
            end
          end

          describe 'searching with 2 statements' do
            before do
              setup_postgres_table([['id', 'SERIAL PRIMARY KEY'], ['text', 'TEXT'], ['tags', 'TEXT[]']])
              ActiveRecordModel.create!(text: 'Test', tags: ['a', 'b'])
              ActiveRecordModel.create!(text: 'Bingo', tags: ['b', 'c'])
            end

            it 'searches using 2 statements' do
              subject = Class.new(Mincer::Base) do
                pg_search [
                    { :columns => %w{"active_record_models"."tags" }, engines: [:array] },
                    { :columns => %w{"active_record_models"."text" }, engines: [:fulltext] }
                ]
              end
              query = subject.new(ActiveRecordModel, { 'pattern' => 'c' })
              query.to_a.count.should eq(1)
              query.to_a.first.text.should == 'Bingo'

              query = subject.new(ActiveRecordModel, { 'pattern' => 'Test' })
              query.to_a.count.should eq(1)
              query.to_a.first.text.should == 'Test'
            end

            it 'searches using 2 statements with aggregator set to :and' do
              subject = Class.new(Mincer::Base) do
                pg_search [
                    { :columns => %w{"active_record_models"."tags" }, engines: [:array] },
                    { :columns => %w{"active_record_models"."text" }, engines: [:fulltext] }
                ], join_with: :and
              end

              ActiveRecordModel.create!(text: 'O', tags: ['O'])

              query = subject.new(ActiveRecordModel, { 'pattern' => 'O' })
              query.to_a.count.should eq(1)
              query.to_a.first.text.should == 'O'
            end
          end


          describe 'searching with array' do
            before do
              setup_postgres_table([['id', 'SERIAL PRIMARY KEY'], ['text', 'TEXT'], ['tags', 'TEXT[]']])
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
                def pg_search_params
                  [{ :columns => %w{"active_record_models"."tags"}, engines: [:array], any_word: true }]
                end
              end
              query = subject.new(ActiveRecordModel, { 'pattern' => 'a, c,d' })
              query.to_a.count.should eq(2)
            end

            it 'includes no items when nothing matched pattern' do
              subject = Class.new(Mincer::Base) do
                def pg_search_params
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


  describe 'configuration of pg_search' do
    before do
      Mincer.config.instance_variable_set('@pg_search', nil)
    end

    describe 'param_name' do
      it 'uses "pattern" as default value for param_name' do
        Mincer.config.pg_search.param_name.should == 'pattern'
      end

      it 'sets param_name string' do
        Mincer.configure do |config|
          config.pg_search do |search|
            search.param_name = 's'
          end
        end
        Mincer.config.pg_search.param_name.should == 's'
      end
    end

    describe 'fulltext_engine' do
      it 'sets "ignore_accent" to true as default value' do
        Mincer.config.pg_search.fulltext_engine[:ignore_accent].should be_true
      end

      it 'sets "any_word" to false as default value' do
        Mincer.config.pg_search.fulltext_engine[:any_word].should be_false
      end

      it 'sets "dictionary" to "simple" as default value' do
        Mincer.config.pg_search.fulltext_engine[:dictionary].should == :simple
      end

      it 'sets "ignore_case" to "false" as default value' do
        Mincer.config.pg_search.fulltext_engine[:ignore_case].should be_false
      end

      it 'sets fulltext_engine options while merging with defaults' do
        Mincer.configure do |config|
          config.pg_search do |search|
            search.fulltext_engine = search.fulltext_engine.merge(ignore_accent: false)
          end
        end
        Mincer.config.pg_search.fulltext_engine.should == { ignore_accent: false, any_word: false, dictionary: :simple, ignore_case: false }
      end
    end

    describe 'trigram_engine' do
      it 'sets "ignore_accent" to true as default value' do
        Mincer.config.pg_search.trigram_engine[:ignore_accent].should be_true
      end

      it 'sets "threshold" to 0.3 as default value' do
        Mincer.config.pg_search.trigram_engine[:threshold].should == 0.3
      end

      it 'sets trigram_engine options while merging with defaults' do
        Mincer.configure do |config|
          config.pg_search do |search|
            search.trigram_engine = search.trigram_engine.merge(threshold: 0.5)
          end
        end
        Mincer.config.pg_search.trigram_engine.should == { ignore_accent: true, threshold: 0.5 }
      end
    end

    describe 'array_engine' do
      it 'sets "ignore_accent" to true as default value' do
        Mincer.config.pg_search.array_engine[:ignore_accent].should be_true
      end

      it 'sets "any_word" to false as default value' do
        Mincer.config.pg_search.array_engine[:any_word].should be_true
      end

      it 'sets array_engine options while merging with defaults' do
        Mincer.configure do |config|
          config.pg_search do |search|
            search.array_engine = search.array_engine.merge(any_word: false)
          end
        end
        Mincer.config.pg_search.array_engine.should == { ignore_accent: true, any_word: false }
      end
    end

  end


end
