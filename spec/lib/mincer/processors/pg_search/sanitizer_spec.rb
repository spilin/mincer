require 'spec_helper'

describe ::Mincer::Processors::PgSearch::Sanitizer do
  before do
    setup_postgres_table
  end

  describe '#sanitize' do
    subject { ::Mincer::Processors::PgSearch::Sanitizer }
    it 'applies "ignore_case" option' do
      subject.sanitize_string('text', :ignore_case).to_sql.should == "lower('text')"
    end

    it 'applies "ignore_accent" option' do
      subject.sanitize_string('text', :ignore_accent).to_sql.should == "unaccent('text')"
    end

    describe 'coalesce option' do
      context 'when postgres extension installed' do
        it 'applies "coalesce" option' do
          subject.sanitize_string('text', :coalesce).to_sql.should == "coalesce('text', '')"
        end
      end
      context 'when postgres extension is unavailable' do
        it 'applies "coalesce" option' do
          Mincer.instance_variable_get('@installed_extensions')[:unaccent] = false
          subject.sanitize_string('text', :coalesce).to_sql.should == 'text'
          Mincer.instance_variable_get('@installed_extensions')[:unaccent] = true
        end
      end
    end

    it 'applies multiple sanitizers' do
      subject.sanitize_string('text', :ignore_case, :ignore_accent, :coalesce).to_sql.should == "unaccent(lower(coalesce('text', '')))"
    end
  end

end
