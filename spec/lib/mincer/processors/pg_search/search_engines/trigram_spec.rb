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
      search_engine = search_engine_class.new('search', [search_statement1])
      search_engine.conditions.to_sql.should == %{((similarity("records"."text", 'search') >= 0.3))}
    end

    it 'generates search condition with one column, one term and "threshold" option set to 0.5' do
      search_statement1 = search_statement_class.new(['"records"."text"'], engines: [:trigram], threshold: 0.5)
      search_engine = search_engine_class.new('search', [search_statement1])
      search_engine.conditions.to_sql.should == %{((similarity("records"."text", 'search') >= 0.5))}
    end

    it 'generates search condition with two columns, one term and no options' do
      search_statement1 = search_statement_class.new(['"records"."text"', '"records"."text2"'], engines: [:trigram])
      search_engine = search_engine_class.new('search', [search_statement1])
      search_engine.conditions.to_sql.should == %{((similarity("records"."text", 'search') >= 0.3) OR (similarity("records"."text2", 'search') >= 0.3))}
    end

    it 'generates search condition with two columns, two terms and no options' do
      search_statement1 = search_statement_class.new(['"records"."text"', '"records"."text2"'], engines: [:trigram])
      search_engine = search_engine_class.new('search word', [search_statement1])
      search_engine.conditions.to_sql.should == %{((similarity("records"."text", 'search word') >= 0.3) OR (similarity("records"."text2", 'search word') >= 0.3))}
    end

    it 'generates search condition with two columns, two terms and option "ignore_accent" set to true ' do
      search_statement1 = search_statement_class.new(['"records"."text"', '"records"."text2"'], engines: [:trigram], ignore_accent: true)
      search_engine = search_engine_class.new('search word', [search_statement1])
      search_engine.conditions.to_sql.should == %{((similarity(unaccent("records"."text"), unaccent('search word')) >= 0.3) OR (similarity(unaccent("records"."text2"), unaccent('search word')) >= 0.3))}
    end

  end

end
