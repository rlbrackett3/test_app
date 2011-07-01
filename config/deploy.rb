#RVM
$:.unshift(File.expand_path('./lib', ENV['rvm_path'])) # Add RVM's lib directory to the load path.
require "rvm/capistrano"                  # Load RVM's capistrano plugin.
set :rvm_ruby_string, "1.9.2"           # Or whatever env you want it to run in.
set :rvm_type, :user                         # when RVM is installed per user rather than system wide.

# Bundler
require "bundler/capistrano"

# General
set :application, "test_app"
set :deploy_server, "192.168.1.107"
set :deploy_to, "/home/rlblood/#{application}"
set :user, 'rlblood' # The server's user for deploys
set :scm_passphrase, "malakas"  # The deploy user's password
set :use_sudo, false

#Git
set :scm, :git
set :scm_username, "rlbrackett3"
set :repository,  "git@guthub.com:rlbrackett3/test_app.git"
set :branch, "master"
set :deploy_via, :remote_cache
# set :git_enable_submodules, 1
set :keep_releases, 5

default_run_options[:pty] = true  # Must be set for the password prompt from git to work
ssh_options[:forward_agent] = true
# Or: `accurev`, `bzr`, `cvs`, `darcs`, `git`, `mercurial`, `perforce`, `subversion` or `none`

# VPS
role :web, "192.168.1.107"                   # Your HTTP server, Apache/etc
role :app, "192.168.1.107"                   # This may be the same as your `Web` server
role :db,  "192.168.1.107", :primary => true # This is where Rails migrations will run
#role :db,  "your slave db-server here"

# Unicorn
set :rails_env, :production
set :unicorn_binary, "unicorn"
set :unicorn_config, "#{current_path}/config/unicorn.rb"
set :unicorn_pid, "#{current_path}/tmp/pids/unicorn.pid"

# if you're still using the script/reaper helper you will need
# these http://github.com/rails/irs_process_scripts

# If you are using Passenger mod_rails uncomment this:
# namespace :deploy do
#   task :start do ; end
#   task :stop do ; end
#   task :restart, :roles => :app, :except => { :no_release => true } do
#     run "#{try_sudo} touch #{File.join(current_path,'tmp','restart.txt')}"
#   end
# end

before "deploy", "deploy:bundle_gems"
before "deploy:restart", "deploy:bundle_gems"
#after "deploy:bundle_gems", "deploy:restart"
#after "deploy:bundle_gems", "deploy:restart"
set :unicorn_pid, "#{deploy_to}/shared/pids/unicorn.pid"
set :bundle, "/var/lib/gems/1.9.1/bin//bundle"
set :unicorn_rails, "/var/lib/gems/1.9.1/bin//unicorn_rails"

namespace :deploy do
  task :bundle_gems do
    run "cd #{deploy_to}/current && #{bundle} install --path vendor/gems"
  end

  task :start, :roles => :app, :except => { :no_release => true} do
    run "#{unicorn_rails} -c #{deploy_to}/current/config/unicorn.rb -D -E production"
  end

  task :stop, :roles => :app, :except => { :no_release => true} do
    run "kill `cat #{unicorn_pid}`"
  end

  task :reload, :roles => :app, :except => { :no_release => true } do
    run "kill -s USR2 `cat #{unicorn_pid}`"
  end

  task :restart, :roles => :app, :except => { :no_release => true } do
    stop
    start
  end
end

after "migration:reload", "deploy:restart"
namespace :migration do
  task :reload, :roles => :app, :except => { :no_release => true } do
    run "cd #{deploy_to}/current && rake db:drop:all && rake db:migrate RAILS_ENV='production' && rake db:seed RAILS_ENV='production'"
  end
end
