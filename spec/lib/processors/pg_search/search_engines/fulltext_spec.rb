require 'spec_helper'

describe ::Mincer::PgSearch::SearchEngines::Fulltext do
  let(:search_column_class) { ::Mincer::Processors::PgSearch::SearchColumn }
  describe '.conditions' do
    context 'when 1 column with option engine: ["fulltext"] passed' do
      it 'generates simplest search condition' do
        engine = search_column_class.new(full_name: '"records"."text"', options: { engines: [:fulltext] })
        <<-SQL
          (((to_tsvector('simple', coalesce(lower("organizers"."public_name"), ''))) @@ (to_tsquery('simple', ''' ' || lower('russ') || ' '''))))
        SQL

        warn '1'*100
        warn engine.conditions
        warn '2'*100

      end
    end
  end

end
