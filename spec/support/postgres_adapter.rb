def setup_basic_postgres_table
  config = if ENV['TRAVIS']
             { adapter: :postgresql, database: 'mincer', username: 'postgres' }
           else
             YAML.load_file File.expand_path(File.dirname(__FILE__) + '../../database.yml')
           end

  ActiveRecord::Base.establish_connection(config)
  ActiveRecord::Base.connection.execute('DROP TABLE IF EXISTS active_record_models')
  ActiveRecord::Base.connection.execute('CREATE TABLE IF NOT EXISTS active_record_models (id SERIAL PRIMARY KEY, text TEXT)')
end