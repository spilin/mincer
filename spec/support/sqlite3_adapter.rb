def setup_basic_sqlite3_table
  ActiveRecord::Base.establish_connection(:adapter => 'sqlite3', :database => ':memory:')
  ActiveRecord::Base.connection.execute('CREATE TABLE active_record_models (id INTEGER PRIMARY KEY, text STRING)')
end