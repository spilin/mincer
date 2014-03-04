require 'spec_helper'

describe ::Mincer::PgSearch::SearchEngines::Array do
  before do
    setup_postgres_table
  end
  subject(:search_engine_class) { ::Mincer::PgSearch::SearchEngines::Array }
  let(:search_statement_class) { ::Mincer::Processors::PgSearch::SearchStatement }

  describe '.search_engine_statements' do
    context 'when 2 columns' do
      it 'stores them in instance variable hash under :or key' do
        search_statement1 = search_statement_class.new(['"records"."text"'], engines: [:array])
        search_statement2 = search_statement_class.new(['"records"."text2"'], engines: [:array])
        search_engine = search_engine_class.new('search', [search_statement1, search_statement2])
        search_engine.send(:search_engine_statements).should include(search_statement1)
        search_engine.send(:search_engine_statements).should include(search_statement2)
      end
    end

    it 'ignores other engines' do
      search_statement1 = search_statement_class.new(['"records"."text"'])
      search_statement2 = search_statement_class.new(['"records"."text2"'], engines: [:trigram])
      search_engine = search_engine_class.new('search', [search_statement1, search_statement2])
      search_engine.send(:search_engine_statements).should == []
      search_engine.send(:search_engine_statements).should == []
    end
  end

  describe '.conditions' do
    it 'generates search condition with one column, one term and no options' do
      search_statement1 = search_statement_class.new(['"records"."text"'], engines: [:array])
      search_engine = search_engine_class.new('search', [search_statement1])
      search_engine.conditions.should == %{(("records"."text") @> ARRAY['search'])}
    end

    it 'generates search condition with two columns, one term and no options' do
      search_statement1 = search_statement_class.new(['"records"."text"', '"records"."text2"'], engines: [:array])
      search_engine = search_engine_class.new('search', [search_statement1])
      search_engine.conditions.should == %{(("records"."text" || "records"."text2") @> ARRAY['search'])}
    end

    it 'generates search condition with two columns, two terms and no options' do
      search_statement1 = search_statement_class.new(['"records"."text"', '"records"."text2"'], engines: [:array])
      search_engine = search_engine_class.new('search word', [search_statement1])
      search_engine.conditions.should == %{(("records"."text" || "records"."text2") @> ARRAY['search','word'])}
    end

    it 'generates search condition with two columns, two terms and option "ignore_accent" set to true ' do
      search_statement1 = search_statement_class.new(['"records"."text"', '"records"."text2"'], engines: [:array], ignore_accent: true)
      search_engine = search_engine_class.new('search word', [search_statement1])
      search_engine.conditions.should == %{(("records"."text" || "records"."text2") @> ARRAY[unaccent('search'),unaccent('word')])}
    end

    #TODO: sanitizer can not be set on array columns since we ned to unpack an reconstruct those arrays. Find a solution
    it 'generates search condition with two columns, two terms and option "any_word" set to true ' do
      search_statement1 = search_statement_class.new(['"records"."text"', '"records"."text2"'], engines: [:array], any_word: true)
      search_engine = search_engine_class.new('search word', [search_statement1])
      search_engine.conditions.should == %{(("records"."text" || "records"."text2") && ARRAY['search','word'])}
    end

    it 'generates search condition with two columns, two terms and option "ignore_accent" and "ignore_case" set to true ' do
      search_statement1 = search_statement_class.new(['"records"."text"', '"records"."text2"'], engines: [:array], ignore_accent: true, ignore_case: true)
      search_engine = search_engine_class.new('search word', [search_statement1])
      search_engine.conditions.should == %{(("records"."text" || "records"."text2") @> ARRAY[unaccent(lower('search')),unaccent(lower('word'))])}
    end
  end

end
