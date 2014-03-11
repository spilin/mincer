require 'spec_helper'


describe ::Mincer::Base do

  it 'passes all missing methods to relation' do
    setup_basic_sqlite3_table
    subject = Class.new(Mincer::Base) do
      pg_search [{ columns: %w{"active_record_models"."tags" }, engines: [:array] }]
    end
    query = subject.new(ActiveRecordModel)
    expect { query.attribute_names }.not_to raise_exception
  end

end
