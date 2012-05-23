# Environment configuration
envo = nil

environment :development do
  envo = "development"
end

environment :staging do
  envo = "staging"
end

environment :production do
  envo = "production"
end

environment :test do
  envo = "test"
end

#------------------------------------------------------------------------------

# Versions
config['version'] = "v1"

# Paths
root_path = File.expand_path('../../..', __FILE__)
config['root_path'] = root_path

# Settings
config['settings'] = YAML.load_file("#{root_path}/config/settings.yml")[envo]

# EventMachine configuration
EM.error_handler do |e|
  logger.error "Error raised during asynchronous event loop: #{e.message}"
end

# Database
db_settings = YAML.load_file("#{root_path}/config/database.yml")[envo]
config['db'] = EventMachine::Synchrony::ConnectionPool.new(:size => 20) do
  conn = EM::Mongo::Connection.new(db_settings['host'], db_settings['port'], 1, {:reconnect_in => 1})
  database = conn.db(db_settings['database'])
  database.authenticate(db_settings['username'], db_settings['password']) if db_settings['username']
  database
end
