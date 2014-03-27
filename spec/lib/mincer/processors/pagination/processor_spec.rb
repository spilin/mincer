require 'spec_helper'

describe ::Mincer::Processors::Pagination::Processor do
  before do
    setup_basic_sqlite3_table
    30.times { |i| ActiveRecordModel.create(text: i) }
  end

  context 'when Kaminari is used for pagination' do
    describe 'paginating with basic model without any Mincer::Base configuration' do
      subject(:model) do
        Class.new(Mincer::Base)
      end

      it 'paginates by with provided page and per_page in args' do
        query = subject.new(ActiveRecordModel, { 'page' => '2', 'per_page' => '20' })
        query.to_a.count.should eq(10)
      end

      it 'paginates by default page(1) and per_page(10) when nothing passed to args' do
        query = subject.new(ActiveRecordModel)
        query.to_a.count.should eq(25)
      end
    end


    describe 'paginating when basic model has disabled pagination' do
      it 'returns all items' do
        subject = Class.new(Mincer::Base) do
          skip_pagination!
        end
        query = subject.new(ActiveRecordModel)
        query.to_a.count.should eq(30)
      end
    end
  end

  context 'when WillPaginate is used for pagination' do
    before do
      ::Mincer::Processors::Pagination::Processor.stub(:kaminari?).and_return(false)
    end

    describe 'paginating with basic model without any Mincer::Base configuration' do
      subject(:model) do
        Class.new(Mincer::Base)
      end

      it 'paginates by with provided page and per_page in args' do
        ActiveRecord::Relation.any_instance.should_receive(:paginate).with(page: '2', per_page: '20')
        subject.new(ActiveRecordModel, { 'page' => '2', 'per_page' => '20' })
      end
    end

    describe 'paginating when basic model has disabled pagination' do
      it 'returns all items' do
        subject = Class.new(Mincer::Base) do
          skip_pagination!
        end
        query = subject.new(ActiveRecordModel)
        query.to_a.count.should eq(30)
      end
    end
  end

  context 'when there is no gem for pagination in loaded' do
    it 'returns all items' do
      subject = Class.new(Mincer::Base)
      ::Mincer::Processors::Pagination::Processor.stub(:kaminari?).and_return(false)
      ::Mincer::Processors::Pagination::Processor.stub(:will_paginate?).and_return(false)

      query = subject.new(ActiveRecordModel)
      query.to_a.count.should eq(30)
    end

  end


  describe 'configuration of pg_search' do
    before do
      Mincer.config.instance_variable_set('@pagination', nil)
    end

    describe 'param_name' do
      it 'uses "page" as default value for page_param_name' do
        Mincer.config.pagination.page_param_name.should == :page
      end

      it 'sets param_name string' do
        Mincer.configure do |config|
          config.pagination do |search|
            search.page_param_name = 's'
          end
        end
        Mincer.config.pagination.page_param_name.should == 's'
      end
    end

    describe 'param_name' do
      it 'uses :per_page as default value for per_page_param_name' do
        Mincer.config.pagination.per_page_param_name.should == :per_page
      end

      it 'sets param_name string' do
        Mincer.configure do |config|
          config.pagination do |search|
            search.per_page_param_name = 's'
          end
        end
        Mincer.config.pagination.per_page_param_name.should == 's'
      end
    end
  end

end
