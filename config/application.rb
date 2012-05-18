# Environment configuration
environment :development do
  config[:env] = 'development'
end

environment :staging do
  config[:env] = 'staging'
end

environment :production do
  config[:env] = 'production'
end

environment :test do
  config[:env] = 'test'
end

#------------------------------------------------------------------------------

# Settings
config[:settings] = YAML.load_file(Api.root_path.join('config/settings.yml'))[config[:env]]

# EventMachine configuration
EM.error_handler do |e|
  logger.error "Error raised during asynchronous event loop: #{e.message}"
end

# Database
db_settings = YAML.load_file(Api.root_path.join('config/database.yml'))[config[:env]]
config['db'] = EventMachine::Synchrony::ConnectionPool.new(:size => 20) do
  conn = EM::Mongo::Connection.new(db_settings['host'], db_settings['port'], 1, {:reconnect_in => 1})
  database = conn.db(db_settings['database'])
  database.authenticate(db_settings['username'], db_settings['password']) if db_settings['username']
  database
end

Api.configure(self)
