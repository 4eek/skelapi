NUM_SERVERS = 10
GROUPS = %w[version status] # TODO: we should build this dynamically.

set :scm,             :git
set :repository,      "git@github.com:madebythem/imbapi.git"
set :branch,          "master"
set :migrate_target,  :current
set :ssh_options,     { :forward_agent => true }
set :rack_env,        "production"
set :deploy_to,       "/data/apps/imbapi"

set :rvm_ruby_string, '1.9.3-p0@imbapi'
set :rvm_type,        :system  # Use system-wide RVM

set :user,            "ubuntu"
set :group,           "ubuntu"
set :use_sudo,        false

role :app,    "ec2-177-71-136-57.sa-east-1.compute.amazonaws.com"
# role :app,    "ec2-67-202-42-216.compute-1.amazonaws.com"
# role :app,    "ec2-23-20-95-61.compute-1.amazonaws.com"

set(:latest_release)  { fetch(:current_path) }
set(:release_path)    { fetch(:current_path) }
set(:current_release) { fetch(:current_path) }

set(:current_revision)  { capture("cd #{current_path}; git rev-parse --short HEAD").strip }
set(:latest_revision)   { capture("cd #{current_path}; git rev-parse --short HEAD").strip }
set(:previous_revision) { capture("cd #{current_path}; git rev-parse --short HEAD@{1}").strip }

default_environment["RACK_ENV"] = 'production'

# Use our ruby-1.9.3-p0@imbapi gemset
# NOTE: You can get this by running 'rvm info' on the destination server
default_environment["PATH"]         = "/usr/share/ruby-rvm/gems/ruby-1.9.3-p0/bin:/usr/share/ruby-rvm/gems/ruby-1.9.3-p0@global/bin:/usr/share/ruby-rvm/rubies/ruby-1.9.3-p0/bin:/usr/share/ruby-rvm/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games"
default_environment["GEM_HOME"]     = "/usr/share/ruby-rvm/gems/ruby-1.9.3-p0"
default_environment["GEM_PATH"]     = "/usr/share/ruby-rvm/gems/ruby-1.9.3-p0:/usr/share/ruby-rvm/gems/ruby-1.9.3-p0@global"
default_environment["RUBY_VERSION"] = "ruby-1.9.3-p0"

default_run_options[:shell] = 'bash'

ssh_options[:keys] = %w(~/.ssh/ec2-imb-sa-east-1.pem ~/.ssh/ec2-imb-eu-west-1.pem ~/.ssh/ec2-imb-us-east-1.pem)

namespace :deploy do
  desc "Deploy the application"
  task :default do
    update
    restart
  end

  desc "Setup the git-based deployment app"
  task :setup, :except => { :no_release => true } do
    dirs = [deploy_to, shared_path]
    dirs += shared_children.map { |d| File.join(shared_path, d) }
    run "#{try_sudo} mkdir -p #{dirs.join(' ')} && #{try_sudo} chmod g+w #{dirs.join(' ')}"
    run "git clone #{repository} #{current_path}"
  end

  task :cold do
    update
    migrate
  end

  task :update do
    transaction do
      update_code
    end
  end

  desc "Update the deployed code."
  task :update_code, :except => { :no_release => true } do
    run "cd #{current_path}; git fetch origin; git reset --hard origin/#{branch}"
    finalize_update
  end

  desc "Update the database (overwritten to avoid symlink)"
  task :migrations do
    transaction do
      update_code
    end
    migrate
    restart
  end

  task :finalize_update, :except => { :no_release => true } do
    run "chmod -R g+w #{latest_release}" if fetch(:group_writable, true)

    # mkdir -p is making sure that the directories are there for some SCM's that don't
    # save empty folders
    run <<-CMD
      rm -rf #{latest_release}/log &&
      ln -s #{shared_path}/log #{latest_release}/log &&
      ln -sf #{shared_path}/config/database.yml #{latest_release}/config/database.yml &&
      ln -sf #{shared_path}/config/settings.yml #{latest_release}/config/settings.yml
    CMD

  end

  desc "Restart"
  task :restart, :except => { :no_release => true }, :on_error => :continue do
    GROUPS.each do |group|
      run "cd #{current_path}; bundle exec god restart #{group}"
    end
  end

  desc "Start"
  task :start, :except => { :no_release => true } do
    GROUPS.each do |group|
      run "cd #{current_path}; bundle exec god start #{group}"
    end
  end

  desc "Stop"
  task :stop, :except => { :no_release => true }, :on_error => :continue do
    GROUPS.each do |group|
      run "cd #{current_path}; bundle exec god stop #{group}"
    end
  end

  namespace :rollback do
    desc "Moves the repo back to the previous version of HEAD"
    task :repo, :except => { :no_release => true } do
      set :branch, "HEAD@{1}"
      deploy.default
    end

    desc "Rewrite reflog so HEAD@{1} will continue to point at the next previous release."
    task :cleanup, :except => { :no_release => true } do
      run "cd #{current_path}; git reflog delete --rewrite HEAD@{1}; git reflog delete --rewrite HEAD@{1}"
    end

    desc "Rolls back to the previously deployed version."
    task :default do
      rollback.repo
      rollback.cleanup
    end
  end
end

def run_rake(cmd)
  run "cd #{current_path}; #{rake} #{cmd}"
end

namespace :god do

  desc "Start"
  task :start do
    run "cd #{current_path}; bundle exec god -c config/god/god.config"
  end

  desc "Terminate"
  task :terminate do
    run "cd #{current_path}; bundle exec god terminate"
  end

  desc "Restart"
  task :restart do
    god.terminate
    got.start
  end

end
