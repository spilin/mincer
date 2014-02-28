require 'spec_helper'

describe ::Mincer::Configuration do

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

      it 'sets fulltext_engine options while merging with defaults' do
        Mincer.configure do |config|
          config.pg_search do |search|
            search.fulltext_engine = search.fulltext_engine.merge(ignore_accent: false)
          end
        end
        Mincer.config.pg_search.fulltext_engine.should == { ignore_accent: false, any_word: false, dictionary: :simple }
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
