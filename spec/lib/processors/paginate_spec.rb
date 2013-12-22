require 'spec_helper'

describe ::Mincer::Processors::Paginate do
  before do
    ActiveRecord::Base.establish_connection(:adapter => 'sqlite3', :database => ':memory:')
    ActiveRecord::Base.connection.execute('CREATE TABLE active_record_models (id INTEGER UNIQUE, text STRING)')
    class ActiveRecordModel < ActiveRecord::Base
    end
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
      pending 'Need to fix test, need to unload Kaminari to test this'
      #::Mincer::Processors::Paginator.any_instance.stub(:kaminari?).and_return(false)
      #require 'will_paginate'
      #require 'will_paginate/active_record'
    end

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

  context 'when there is no gem for pagination in loaded' do
    it 'returns all items' do
      subject = Class.new(Mincer::Base)
      ::Mincer::Processors::Paginate.any_instance.stub(:kaminari?).and_return(false)
      ::Mincer::Processors::Paginate.any_instance.stub(:will_paginate?).and_return(false)

      query = subject.new(ActiveRecordModel)
      query.to_a.count.should eq(30)
    end

  end

end
