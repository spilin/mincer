class ActiveRecordModel < ActiveRecord::Base
end
def setup_postgres_table(columns = [['id', 'SERIAL PRIMARY KEY'], ['text', 'TEXT']])
  config = if ENV['TRAVIS']
             { adapter: :postgresql, database: 'mincer', username: 'postgres' }
           else
             YAML.load_file File.expand_path(File.dirname(__FILE__) + '../../database.yml')
           end

  ActiveRecord::Base.establish_connection(config)
  ActiveRecord::Base.connection.execute('DROP TABLE IF EXISTS active_record_models')

  columns_sql = columns.map {|column| column.join(' ') }.join(',')
  ActiveRecord::Base.connection.execute("CREATE TABLE IF NOT EXISTS active_record_models (#{columns_sql})")
  ActiveRecordModel.reset_column_information
end


