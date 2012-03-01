require 'bundler'
Bundler::GemHelper.install_tasks

require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new(:spec) do |t|
  t.rspec_opts = ["-c", "-f progress", "-r ./spec/spec_helper.rb"]
  t.pattern = 'spec/**/*_spec.rb'
end

task :default => :spec

namespace :db do
  desc "Migrate the database"
  task(:migrate => :environment) do

    # Database
    db_settings = YAML.load_file(Api.root_path.join('config/database.yml'))[:environment]
    conn = EM::Mongo::Connection.new(db_settings['host'], db_settings['port'], 1, {:reconnect_in => 1})
    conn.db(db_settings['database'])

    # for demo purposes, some dummy accounts
    timebin = ((Time.now.to_i / 3600).floor * 3600)

    # This user's calls should all go through
    conn.collection(:account_info).save({
      :_id => 'i_am_awesome', 'valid' => true,  'max_call_rate' => 1_000_000 
    })

    # this user's account is disabled
    conn.collection(:account_info).save({
      :_id => 'i_am_lame',    'valid' => false, 'max_call_rate' => 1_000 
    })

    # this user has not been seen, but will very quickly hit their limit
    conn.collection(:account_info).save({
      :_id => 'i_am_limited', 'valid' => true, 'max_call_rate' =>     10 
    })
    conn.collection(:usage_info).save({
      :_id => "i_am_limited-#{timebin}", 'calls' =>  0 
    })

    # fakes a user with a bunch of calls already made this hour -- two more = no yuo
    conn.collection(:account_info).save({
      :_id => 'i_am_busy',    'valid' => true, 'max_call_rate' =>  1_000 
    })
    conn.collection(:usage_info).save({
      :_id => "i_am_busy-#{timebin}", 'calls' =>  999 
    })

  end
end

