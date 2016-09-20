require 'spec_helper'

describe ::Mincer::Processors::Sorting::Processor do
  before do
    setup_basic_sqlite3_table
    %w{a c b}.each { |i| ActiveRecordModel.create(text: i) }
  end

  describe 'config' do
    it 'defines method with pg_options' do
      subject = Class.new(Mincer::Base) do
        pg_search [{ columns: %w{"active_record_models"."tags" }, engines: [:array] }]
      end
      query = subject.new(ActiveRecordModel)
      query.send(:pg_search_params).should == [{ columns: %w{"active_record_models"."tags" }, engines: [:array] }]
    end
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

  context 'when sort and order is not given in params' do
    it 'sets @mincer.default_sorting to true' do
      subject = Class.new(Mincer::Base)
      query = subject.new(ActiveRecordModel, { })
      expect(query.default_sorting).to eq(true)
    end
  end

  context 'when sort is given in params' do
    it 'sets @mincer.default_sorting to false' do
      subject = Class.new(Mincer::Base)
      query = subject.new(ActiveRecordModel, { 'sort' => 'text' })
      expect(query.default_sorting).to eq(false)
    end
  end

  context 'when order is given in params' do
    it 'sets @mincer.default_sorting to false' do
      subject = Class.new(Mincer::Base)
      query = subject.new(ActiveRecordModel, { 'order' => 'asc' })
      expect(query.default_sorting).to eq(false)
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


  describe 'configuration of sorting' do
    before do
      Mincer.config.instance_variable_set('@sorting', nil)
    end

    describe 'sort_param_name' do
      it 'uses "sort" as default value for sort_param_name' do
        Mincer.config.sorting.sort_param_name.should == :sort
      end

      it 'sets sort_param_name string' do
        Mincer.configure do |config|
          config.sorting do |search|
            search.sort_param_name = 's'
          end
        end
        Mincer.config.sorting.sort_param_name.should == 's'
      end
    end

    describe 'sort_attribute' do
      it 'uses :per_page as default value for sort_attribute' do
        Mincer.config.sorting.sort_attribute.should == :id
      end

      it 'sets sort_attribute string' do
        Mincer.configure do |config|
          config.sorting do |search|
            search.sort_attribute = 's'
          end
        end
        Mincer.config.sorting.sort_attribute.should == 's'
      end
    end

    describe 'order_param_name' do
      it 'uses "order" as default value for order_param_name' do
        Mincer.config.sorting.order_param_name.should == :order
      end

      it 'sets order_param_name string' do
        Mincer.configure do |config|
          config.sorting do |search|
            search.order_param_name = 's'
          end
        end
        Mincer.config.sorting.order_param_name.should == 's'
      end
    end

    describe 'order_attribute' do
      it 'uses :asc as default value for order_attribute' do
        Mincer.config.sorting.order_attribute.should == :asc
      end

      it 'sets order_attribute string' do
        Mincer.configure do |config|
          config.sorting do |search|
            search.order_attribute = 's'
          end
        end
        Mincer.config.sorting.order_attribute.should == 's'
      end
    end

    describe 'asc_class' do
      it 'uses "sorted order_down" as default value for asc_class' do
        Mincer.config.sorting.asc_class.should == 'sorted order_down'
      end

      it 'sets asc_class string' do
        Mincer.configure do |config|
          config.sorting do |search|
            search.asc_class = 's'
          end
        end
        Mincer.config.sorting.asc_class.should == 's'
      end
    end

    describe 'desc_class' do
      it 'uses "sorted order_up" as default value for desc_class' do
        Mincer.config.sorting.desc_class.should == 'sorted order_up'
      end

      it 'sets desc_class string' do
        Mincer.configure do |config|
          config.sorting do |search|
            search.desc_class = 's'
          end
        end
        Mincer.config.sorting.desc_class.should == 's'
      end
    end
  end

end
