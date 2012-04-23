# Enable multi-stage support
require 'capistrano/ext/multistage'

# Run bundler after each deploy
require 'bundler/capistrano'

# Add RVM's lib directory to the load path.
$:.unshift(File.expand_path('./lib', ENV['rvm_path']))

# Load RVM's capistrano plugin.
require "rvm/capistrano"

# Stage definitions
set :stages,        %w(staging production)
set :default_stage, "staging"

