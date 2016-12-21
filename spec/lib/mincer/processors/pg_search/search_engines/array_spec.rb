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
        search_engine = search_engine_class.new({ pattern: 'search' }, [search_statement1, search_statement2])
        search_engine.send(:search_engine_statements).should include(search_statement1)
        search_engine.send(:search_engine_statements).should include(search_statement2)
      end
    end

    it 'ignores other engines' do
      search_statement1 = search_statement_class.new(['"records"."text"'])
      search_statement2 = search_statement_class.new(['"records"."text2"'], engines: [:trigram])
      search_engine = search_engine_class.new({ pattern: 'search' }, [search_statement1, search_statement2])
      search_engine.send(:search_engine_statements).should == []
      search_engine.send(:search_engine_statements).should == []
    end
  end

  describe '.conditions' do
    it 'generates search condition with one column, one term and no options' do
      search_statement1 = search_statement_class.new(['"records"."text"'], engines: [:array])
      search_engine = search_engine_class.new({ pattern: 'search' }, [search_statement1])
      search_engine.conditions.to_sql.should == %{(("records"."text"::text[]) @> ARRAY['search'])}
    end

    it 'generates search condition with two columns, one term and no options' do
      search_statement1 = search_statement_class.new(['"records"."text"', '"records"."text2"'], engines: [:array])
      search_engine = search_engine_class.new({ pattern: 'search' }, [search_statement1])
      search_engine.conditions.to_sql.should == %{(("records"."text"::text[] || "records"."text2"::text[]) @> ARRAY['search'])}
    end

    it 'generates search condition with two columns, two terms and no options' do
      search_statement1 = search_statement_class.new(['"records"."text"', '"records"."text2"'], engines: [:array])
      search_engine = search_engine_class.new({ pattern: 'search word' }, [search_statement1])
      search_engine.conditions.to_sql.should == %{(("records"."text"::text[] || "records"."text2"::text[]) @> ARRAY['search','word'])}
    end

    it 'generates search condition with two columns, two terms and option "ignore_accent" set to true ' do
      search_statement1 = search_statement_class.new(['"records"."text"', '"records"."text2"'], engines: [:array], ignore_accent: true)
      search_engine = search_engine_class.new({ pattern: 'search word' }, [search_statement1])
      search_engine.conditions.to_sql.should == %{((unaccent("records"."text"::text)::text[] || unaccent("records"."text2"::text)::text[]) @> ARRAY[unaccent('search'),unaccent('word')])}
    end

    #TODO: sanitizer can not be set on array columns since we ned to unpack an reconstruct those arrays. Find a solution
    it 'generates search condition with two columns, two terms and option "any_word" set to true ' do
      search_statement1 = search_statement_class.new(['"records"."text"', '"records"."text2"'], engines: [:array], any_word: true)
      search_engine = search_engine_class.new({ pattern: 'search word' }, [search_statement1])
      search_engine.conditions.to_sql.should == %{(("records"."text"::text[] || "records"."text2"::text[]) && ARRAY['search','word'])}
    end

    it 'generates search condition with two columns, two terms and option "ignore_accent" and "ignore_case" set to true ' do
      search_statement1 = search_statement_class.new(['"records"."text"', '"records"."text2"'], engines: [:array], ignore_accent: true, ignore_case: true)
      search_engine = search_engine_class.new({ pattern: 'search word' }, [search_statement1])
      search_engine.conditions.to_sql.should == %{((unaccent(lower("records"."text"::text))::text[] || unaccent(lower("records"."text2"::text))::text[]) @> ARRAY[unaccent(lower('search')),unaccent(lower('word'))])}
    end

    it 'generates search condition with one column, one term, two statements and no options' do
      search_statement1 = search_statement_class.new(['"records"."text"'], engines: [:array])
      search_statement2 = search_statement_class.new(['"records"."text2"'], engines: [:array], any_word: true)
      search_engine = search_engine_class.new({ pattern: 'search' }, [search_statement1, search_statement2])
      search_engine.conditions.to_sql.should == %{((("records"."text"::text[]) @> ARRAY['search']) OR (("records"."text2"::text[]) && ARRAY['search']))}
    end

    it 'generates search condition with one column, one term, two statements and no "param_name" options set to "s"' do
      search_statement1 = search_statement_class.new(['"records"."text"'], engines: [:array])
      search_statement2 = search_statement_class.new(['"records"."text2"'], engines: [:array], any_word: true, param_name: 's')
      search_engine = search_engine_class.new({ pattern: 'search', s: 'word' }, [search_statement1, search_statement2])
      search_engine.conditions.to_sql.should == %{((("records"."text"::text[]) @> ARRAY['search']) OR (("records"."text2"::text[]) && ARRAY['word']))}
    end
  end

end
