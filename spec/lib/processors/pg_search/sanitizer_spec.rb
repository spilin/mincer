require 'spec_helper'

describe ::Mincer::Processors::PgSearch::Sanitizer do
  before do
    setup_postgres_table
  end

  describe '#sanitize' do
    subject { ::Mincer::Processors::PgSearch::Sanitizer }
    it 'applies "ignore_case" option' do
      subject.sanitize('text', :ignore_case).to_sql.should == 'lower(text)'
    end

    it 'applies "ignore_accent" option' do
      subject.sanitize('text', :ignore_accent).to_sql.should == 'unaccent(text)'
    end

    it 'applies "coalesce" option' do
      subject.sanitize('text', :coalesce).to_sql.should == "coalesce(text, '')"
    end

    it 'applies multiple sanitizers' do
      subject.sanitize('text', :ignore_case, :ignore_accent, :coalesce).to_sql.should == "coalesce(unaccent(lower(text)), '')"
    end
  end

end
