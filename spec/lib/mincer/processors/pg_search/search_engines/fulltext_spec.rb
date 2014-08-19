require 'spec_helper'

describe ::Mincer::PgSearch::SearchEngines::Fulltext do
  before do
    setup_postgres_table
  end
  subject(:search_engine_class) { ::Mincer::PgSearch::SearchEngines::Fulltext }
  let(:search_statement_class) { ::Mincer::Processors::PgSearch::SearchStatement }

  describe '.search_engine_statements' do
    context 'when 2 columns' do
      it 'stores them in instance variable hash under :or key' do
        search_statement1 = search_statement_class.new(['"records"."text"'], engines: [:fulltext])
        search_statement2 = search_statement_class.new(['"records"."text2"'], engines: [:fulltext])
        search_engine = search_engine_class.new({ pattern: 'search' }, [search_statement1, search_statement2])
        search_engine.send(:search_engine_statements).should include(search_statement1)
        search_engine.send(:search_engine_statements).should include(search_statement2)
      end
    end

    it 'ignores other engines' do
      search_statement1 = search_statement_class.new(['"records"."text"'])
      search_statement2 = search_statement_class.new(['"records"."text2"'], engines: [:array])
      search_engine = search_engine_class.new({ pattern: 'search' }, [search_statement1, search_statement2])
      search_engine.send(:search_engine_statements).should == []
      search_engine.send(:search_engine_statements).should == []
    end
  end

  describe '.conditions' do

    context 'when only one column is searchable' do
      it 'generates search condition with one column, one term and no options without columns wrapped with coalesce' do
        search_statement1 = search_statement_class.new(['"records"."text"'], engines: [:fulltext])
        search_engine = search_engine_class.new({ pattern: 'search' }, [search_statement1])
        search_engine.conditions.to_sql.should == %{((to_tsvector('simple', "records"."text") @@ to_tsquery('simple', 'search')))}
      end
    end

    context 'when 2 columns is searchable' do
      it 'generates search condition with two columns, one term and no options' do
        search_statement1 = search_statement_class.new(['"records"."text"', '"records"."text2"'], engines: [:fulltext])
        search_engine = search_engine_class.new({ pattern: 'search' }, [search_statement1])
        search_engine.conditions.to_sql.should == %{((to_tsvector('simple', \"records\".\"text\") @@ to_tsquery('simple', 'search')) OR (to_tsvector('simple', \"records\".\"text2\") @@ to_tsquery('simple', 'search')))}
      end

      it 'generates search condition with two columns, two terms and no options' do
        search_statement1 = search_statement_class.new(['"records"."text"', '"records"."text2"'], engines: [:fulltext])
        search_engine = search_engine_class.new({ pattern: 'search word' }, [search_statement1])
        search_engine.conditions.to_sql.should == %{((to_tsvector('simple', \"records\".\"text\") @@ to_tsquery('simple', 'search' || ' & ' || 'word')) OR (to_tsvector('simple', \"records\".\"text2\") @@ to_tsquery('simple', 'search' || ' & ' || 'word')))}
      end

      it 'generates search condition with two columns, two terms and option "any_word" set to true ' do
        search_statement1 = search_statement_class.new(['"records"."text"', '"records"."text2"'], engines: [:fulltext], any_word: true)
        search_engine = search_engine_class.new({ pattern: 'search word' }, [search_statement1])
        search_engine.conditions.to_sql.should == %{((to_tsvector('simple', \"records\".\"text\") @@ to_tsquery('simple', 'search' || ' | ' || 'word')) OR (to_tsvector('simple', \"records\".\"text2\") @@ to_tsquery('simple', 'search' || ' | ' || 'word')))}
      end

      it 'generates search condition with two columns, two terms and option "any_word" set to true while escaping special characters' do
        search_statement1 = search_statement_class.new(['"records"."text"', '"records"."text2"'], engines: [:fulltext], any_word: true)
        search_engine = search_engine_class.new({ pattern: 'search word!(:&|) !' }, [search_statement1])
        search_engine.conditions.to_sql.should == %{((to_tsvector('simple', \"records\".\"text\") @@ to_tsquery('simple', 'search' || ' | ' || 'word')) OR (to_tsvector('simple', \"records\".\"text2\") @@ to_tsquery('simple', 'search' || ' | ' || 'word')))}
      end

      it 'generates search condition with two columns, two terms and option "ignore_accent" set to true ' do
        search_statement1 = search_statement_class.new(['"records"."text"', '"records"."text2"'], engines: [:fulltext], ignore_accent: true)
        search_engine = search_engine_class.new({ pattern: 'search word' }, [search_statement1])
        search_engine.conditions.to_sql.should == %{((to_tsvector('simple', unaccent(\"records\".\"text\")) @@ to_tsquery('simple', unaccent('search') || ' & ' || unaccent('word'))) OR (to_tsvector('simple', unaccent(\"records\".\"text2\")) @@ to_tsquery('simple', unaccent('search') || ' & ' || unaccent('word'))))}
      end

      context 'when unaccent set only on query' do
        it 'generates search condition with two columns, two terms and option "ignore_accent" set to be used on query ' do
          search_statement1 = search_statement_class.new(['"records"."text"', '"records"."text2"'], engines: [:fulltext], ignore_accent: {query: true})
          search_engine = search_engine_class.new({ pattern: 'search word' }, [search_statement1])
          search_engine.conditions.to_sql.should == %{((to_tsvector('simple', \"records\".\"text\") @@ to_tsquery('simple', unaccent('search') || ' & ' || unaccent('word'))) OR (to_tsvector('simple', \"records\".\"text2\") @@ to_tsquery('simple', unaccent('search') || ' & ' || unaccent('word'))))}
        end
      end

      it 'generates search condition with two columns, two terms and option "ignore_accent" and "ignore_case" set to true ' do
        search_statement1 = search_statement_class.new(['"records"."text"', '"records"."text2"'], engines: [:fulltext], ignore_accent: true, ignore_case: true)
        search_engine = search_engine_class.new({ pattern: 'search word' }, [search_statement1])
        search_engine.conditions.to_sql.should == %{((to_tsvector('simple', unaccent(lower(\"records\".\"text\"))) @@ to_tsquery('simple', unaccent(lower('search')) || ' & ' || unaccent(lower('word')))) OR (to_tsvector('simple', unaccent(lower(\"records\".\"text2\"))) @@ to_tsquery('simple', unaccent(lower('search')) || ' & ' || unaccent(lower('word')))))}
      end
    end

    it 'generates search condition with one column, one term and option "dictionary" set to :english' do
      search_statement1 = search_statement_class.new(['"records"."text"'], engines: [:fulltext], dictionary: :english)
      search_engine = search_engine_class.new({ pattern: 'search' }, [search_statement1])
      search_engine.conditions.to_sql.should == %{((to_tsvector('english', "records"."text") @@ to_tsquery('english', 'search')))}
    end

    it 'generates search condition with two search statements one column, one term and no options' do
      search_statement1 = search_statement_class.new(['"records"."text"'], engines: [:fulltext])
      search_statement2 = search_statement_class.new(['"records"."text2"'], engines: [:fulltext])
      search_engine = search_engine_class.new({ pattern: 'search' }, [search_statement1, search_statement2])
      search_engine.conditions.to_sql.should == %{((to_tsvector('simple', "records"."text") @@ to_tsquery('simple', 'search')) OR (to_tsvector('simple', "records"."text2") @@ to_tsquery('simple', 'search')))}
    end

    it 'generates search condition with one column, one term, two statements and no options' do
      search_statement1 = search_statement_class.new(['"records"."text"'], engines: [:fulltext])
      search_statement2 = search_statement_class.new(['"records"."text2"'], engines: [:fulltext])
      search_engine = search_engine_class.new({ pattern: 'search' }, [search_statement1, search_statement2])
      search_engine.conditions.to_sql.should == %{((to_tsvector('simple', \"records\".\"text\") @@ to_tsquery('simple', 'search')) OR (to_tsvector('simple', \"records\".\"text2\") @@ to_tsquery('simple', 'search')))}
    end

    it 'generates search condition with one column, one term, two statements and "param_name" option set to "s"' do
      search_statement1 = search_statement_class.new(['"records"."text"'], engines: [:fulltext])
      search_statement2 = search_statement_class.new(['"records"."text2"'], engines: [:fulltext], param_name: 's')
      search_engine = search_engine_class.new({ pattern: 'search', s: 'word' }, [search_statement1, search_statement2])
      search_engine.conditions.to_sql.should == %{((to_tsvector('simple', \"records\".\"text\") @@ to_tsquery('simple', 'search')) OR (to_tsvector('simple', \"records\".\"text2\") @@ to_tsquery('simple', 'word')))}
    end
  end

end
