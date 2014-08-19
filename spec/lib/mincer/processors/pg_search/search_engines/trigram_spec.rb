require 'spec_helper'

describe ::Mincer::PgSearch::SearchEngines::Trigram do
  before do
    setup_postgres_table
  end
  subject(:search_engine_class) { ::Mincer::PgSearch::SearchEngines::Trigram }
  let(:search_statement_class) { ::Mincer::Processors::PgSearch::SearchStatement }

  describe '.search_engine_statements' do
    context 'when 2 columns' do
      it 'stores them in instance variable hash under :or key' do
        search_statement1 = search_statement_class.new(['"records"."text"'], engines: [:trigram])
        search_statement2 = search_statement_class.new(['"records"."text2"'], engines: [:trigram])
        search_engine = search_engine_class.new('search', [search_statement1, search_statement2])
        search_engine.send(:search_engine_statements).should include(search_statement1)
        search_engine.send(:search_engine_statements).should include(search_statement2)
      end
    end

    it 'ignores other engines' do
      search_statement1 = search_statement_class.new(['"records"."text"'])
      search_statement2 = search_statement_class.new(['"records"."text2"'], engines: [:array])
      search_engine = search_engine_class.new('search', [search_statement1, search_statement2])
      search_engine.send(:search_engine_statements).should == []
      search_engine.send(:search_engine_statements).should == []
    end
  end

  describe '.conditions' do
    it 'generates search condition with one column, one term and no options' do
      search_statement1 = search_statement_class.new(['"records"."text"'], engines: [:trigram])
      search_engine = search_engine_class.new({ pattern: 'search' }, [search_statement1])
      search_engine.conditions.to_sql.should == %{(("records"."text" % 'search'))}
    end

    it 'generates search condition with one column, one term and "threshold" option set to 0.5' do
      search_statement1 = search_statement_class.new(['"records"."text"'], engines: [:trigram], threshold: 0.5)
      search_engine = search_engine_class.new({ pattern: 'search' }, [search_statement1])
      search_engine.conditions.to_sql.should == %{((similarity("records"."text", 'search') >= 0.5))}
    end

    it 'generates search condition with two columns, one term and no options' do
      search_statement1 = search_statement_class.new(['"records"."text"', '"records"."text2"'], engines: [:trigram])
      search_engine = search_engine_class.new({ pattern: 'search' }, [search_statement1])
      search_engine.conditions.to_sql.should == %{(("records"."text" % 'search') OR ("records"."text2" % 'search'))}
    end

    it 'generates search condition with two columns, two terms and no options' do
      search_statement1 = search_statement_class.new(['"records"."text"', '"records"."text2"'], engines: [:trigram])
      search_engine = search_engine_class.new({ pattern: 'search word' }, [search_statement1])
      search_engine.conditions.to_sql.should == %{(("records"."text" % 'search word') OR ("records"."text2" % 'search word'))}
    end

    it 'generates search condition with two columns, two terms and option "ignore_accent" set to true ' do
      search_statement1 = search_statement_class.new(['"records"."text"', '"records"."text2"'], engines: [:trigram], ignore_accent: true)
      search_engine = search_engine_class.new({ pattern: 'search word' }, [search_statement1])
      search_engine.conditions.to_sql.should == %{((unaccent("records"."text") % unaccent('search word')) OR (unaccent("records"."text2") % unaccent('search word')))}
    end

    it 'generates search condition with one column, one term, two statements and no options' do
      search_statement1 = search_statement_class.new(['"records"."text"'], engines: [:trigram])
      search_statement2 = search_statement_class.new(['"records"."text2"'], engines: [:trigram])
      search_engine = search_engine_class.new({ pattern: 'search' }, [search_statement1, search_statement2])
      search_engine.conditions.to_sql.should == %{(("records"."text" % 'search') OR ("records"."text2" % 'search'))}
    end

    it 'generates search condition with one column, one term, two statements and "param_name" option set to "s"' do
      search_statement1 = search_statement_class.new(['"records"."text"'], engines: [:trigram])
      search_statement2 = search_statement_class.new(['"records"."text2"'], engines: [:trigram], param_name: 's')
      search_engine = search_engine_class.new({ pattern: 'search', s: 'word' }, [search_statement1, search_statement2])
      search_engine.conditions.to_sql.should == %{(("records"."text" % 'search') OR ("records"."text2" % 'word'))}
    end

  end

  describe '.rank' do
    it 'generates rank with one column, one term and no options' do
      search_statement1 = search_statement_class.new(['"records"."text"'], engines: [:trigram])
      search_engine = search_engine_class.new({ pattern: 'search' }, [search_statement1])
      search_engine.rank.to_sql.should == %{(similarity("records"."text", 'search'))}
    end

    it 'generates rank with two columns, one term and no options' do
      search_statement1 = search_statement_class.new(['"records"."text"', '"records"."text2"'], engines: [:trigram])
      search_engine = search_engine_class.new({ pattern: 'search' }, [search_statement1])
      search_engine.rank.to_sql.should == %{(similarity("records"."text", 'search') + similarity("records"."text2", 'search'))}
    end
  end

end
