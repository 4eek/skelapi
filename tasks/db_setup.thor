require 'mongo'

class Database < Thor
  desc "seed ENV", "Setup the test DB with seed data."
  def seed(env)
    puts "You supplied the env: #{env}"
    if env == 'production'
      puts "No prodution DB seed right now."
      exit 1
    else
      # Database
      db_settings = YAML.load_file(File.join(File.dirname(__FILE__), '../config/', 'database.yml'))[env]
      puts db_settings.to_yaml
      conn = Mongo::Connection.new(db_settings['host'], db_settings['port']).db(db_settings['database'])

      # for demo purposes, some dummy accounts
      timebin = ((Time.now.to_i / 3600).floor * 3600)

      # This user's calls should all go through
      conn.collection(:account_info).save({
        :_id => 'i_am_awesome', 'active' => true,  'max_call_rate' => 1_000_000 
      })

      # this user's account is disabled
      conn.collection(:account_info).save({
        :_id => 'i_am_lame',    'active' => false, 'max_call_rate' => 1_000 
      })

      # this user has not been seen, but will very quickly hit their limit
      conn.collection(:account_info).save({
        :_id => 'i_am_limited', 'active' => true, 'max_call_rate' =>     10 
      })
      conn.collection(:usage_info).save({
        :_id => "i_am_limited-#{timebin}", 'calls' =>  0 
      })

      # fakes a user with a bunch of calls already made this hour -- two more = no yuo
      conn.collection(:account_info).save({
        :_id => 'i_am_busy',    'active' => true, 'max_call_rate' =>  1_000 
      })
      conn.collection(:usage_info).save({
        :_id => "i_am_busy-#{timebin}", 'calls' =>  999 
      })
    end
  end
end

