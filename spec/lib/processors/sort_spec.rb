require 'spec_helper'

describe ::Mincer::Processors::Sort do
  before do
    setup_basic_sqlite3_table
    class ActiveRecordModel < ActiveRecord::Base
    end
    %w{a c b}.each { |i| ActiveRecordModel.create(text: i) }
  end

  describe 'sorting with basic model without any Mincer::Base configuration' do
    subject(:model) do
      Class.new(Mincer::Base)
    end

    it 'sorts by valid attribute and order when they are passed in args' do
      query = subject.new(ActiveRecordModel, { 'sort' => 'text', 'order' => 'DESC' })
      query.to_a.map(&:text).should == %w{c b a}
    end

    it 'sorts by default attributes(id) abd order(ASC) when nothing passed to args' do
      query = subject.new(ActiveRecordModel)
      query.to_a.map(&:text).should == %w{a c b}
    end

    it 'ignores sort attribute that is not allowed and use default(id)' do
      query = subject.new(ActiveRecordModel, { 'sort' => 'text2', 'order' => 'DESC' })
      query.to_a.map(&:text).should == %w{b c a}
    end

    it 'ignores order that is not allowed and use default(ASC)' do
      query = subject.new(ActiveRecordModel, { 'sort' => 'text', 'order' => 'DESCA' })
      query.to_a.map(&:text).should == %w{a b c}
    end
  end


  describe 'sorting with basic model with defaults changed' do
    it 'sorts by default attributes(id) abd order(ASC) when nothing passed to args' do
      subject = Class.new(Mincer::Base) do
        def default_sort_attribute
          'text'
        end
        def default_sort_order
          'DESC'
        end
      end
      query = subject.new(ActiveRecordModel)
      query.to_a.map(&:text).should == %w{c b a}
    end
  end

  describe 'sorting with basic model with defaults changed' do
    it 'sorts by default attributes(id) abd order(ASC) when nothing passed to args' do
      subject = Class.new(Mincer::Base) do
        def allowed_sort_attributes
          ['id']
        end
      end
      query = subject.new(ActiveRecordModel, { 'sort' => 'text' })
      query.to_a.map(&:text).should == %w{a c b}
    end
  end


  describe 'sorting when basic model has disabled sorting' do
    it 'sorts by default attributes(id) abd order(ASC) when nothing passed to args' do
      subject = Class.new(Mincer::Base) do
        skip_sorting!
      end
      query = subject.new(ActiveRecordModel, { 'sort' => 'text' })
      query.to_a.map(&:text).should == %w{a c b}
    end
  end


end
