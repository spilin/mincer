require "spec_helper"

describe Mincer::Processors::PgSearch::SearchStatement do
  describe '.sanitizers' do
    let(:search_statement_class) { Mincer::Processors::PgSearch::SearchStatement }

    it 'returns sanitizers that has true in options' do
      search_statement = search_statement_class.new('text', {"ignore_accent"=>true, "any_word"=>false, "dictionary"=>:simple, "ignore_case"=>false, "engines"=>[:fulltext]} )
      search_statement.sanitizers.should == [:ignore_accent]
    end

    context 'when key "document" is given' do
      it 'returns only sanitizers with true value in options' do
        search_statement = search_statement_class.new('text', {"ignore_accent"=>true, "any_word"=>false, "dictionary"=>:simple, "ignore_case"=>false, "engines"=>[:fulltext]} )
        search_statement.sanitizers(:document).should == [:ignore_accent]
      end

      it 'returns sanitizers when sanitizer set as hash with type set to true in options' do
        search_statement = search_statement_class.new('text', {"ignore_accent"=>true, "any_word"=>false, "dictionary"=>:simple, "ignore_case"=> { :document => true}, "engines"=>[:fulltext]} )
        search_statement.sanitizers(:document).size.should == 2
        search_statement.sanitizers(:document).should include(:ignore_accent)
        search_statement.sanitizers(:document).should include(:ignore_case)
      end

      it 'returns sanitizers when sanitizer set as hash with type set to false in options' do
        search_statement = search_statement_class.new('text', {"ignore_accent"=>true, "any_word"=>false, "dictionary"=>:simple, "ignore_case"=> { :query => true}, "engines"=>[:fulltext]} )
        search_statement.sanitizers(:document).size.should == 1
        search_statement.sanitizers(:document).should == [:ignore_accent]
      end
    end

    context 'when key "query" is given' do
      it 'returns only sanitizers with true value in options' do
        search_statement = search_statement_class.new('text', {"ignore_accent"=>true, "any_word"=>false, "dictionary"=>:simple, "ignore_case"=>false, "engines"=>[:fulltext]} )
        search_statement.sanitizers(:query).should == [:ignore_accent]
      end

      it 'returns sanitizers when sanitizer set as hash with type set to true in options' do
        search_statement = search_statement_class.new('text', {"ignore_accent"=>true, "any_word"=>false, "dictionary"=>:simple, "ignore_case"=> { :query => true}, "engines"=>[:fulltext]} )
        search_statement.sanitizers(:query).size.should == 2
        search_statement.sanitizers(:query).should include(:ignore_accent)
        search_statement.sanitizers(:query).should include(:ignore_case)
      end

      it 'returns sanitizers when sanitizer set as hash with type set to false in options' do
        search_statement = search_statement_class.new('text', {"ignore_accent"=>true, "any_word"=>false, "dictionary"=>:simple, "ignore_case"=> { :document => true}, "engines"=>[:fulltext]} )
        search_statement.sanitizers(:query).size.should == 1
        search_statement.sanitizers(:query).should == [:ignore_accent]
      end

    end


  end
end
