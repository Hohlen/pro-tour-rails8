# Must match the capistrano version pinned in the Gemfile.
lock "~> 3.20.1"

# The new cPanel server for the Rails 8 apps. cPanel's Application Manager has this app registered at
# /home/ptfghost/apps/protourfantasygolf.com (PassengerAppRoot ".../current"), so that is where it deploys.
application = "protourfantasygolf.com"
set :application, application

set :repo_url, "git@github.com:Hohlen/pro-tour-rails8.git"
set :branch, "main"

# The server pulls from GitHub using the deploying workstation's SSH key.
# https://docs.github.com/en/developers/overview/managing-deploy-keys#ssh-agent-forwarding
set :ssh_options, { forward_agent: true }
set :pty, true

# cPanel mounts /tmp noexec, so the git SSH wrapper script Capistrano uploads there can't be run ("cannot exec ...:
# Permission denied"). The account's home directory is executable.
set :tmp_dir, "/home/ptfghost/tmp"

set :format, :airbrussh
set :log_level, :info # :debug

# This server has no RVM: Ruby 3.4.11 lives in /opt/rubies and is what Passenger is set to run this app with
# (cPanel Application Manager). Putting it first on the PATH makes the deploy's `bundle install` use the same Ruby.
set :default_env, { path: "/opt/rubies/ruby-3.4.11/bin:$PATH" }
set :deploy_to, "/home/ptfghost/apps/#{application}"
set :keep_releases, 3 # how many old releases do we want to keep

# config/master.key decrypts config/credentials.yml.enc and is not in git. Put it on the server once, at
# #{deploy_to}/shared/config/master.key; every release then gets a symlink to it. The deploy stops early
# (deploy:check:linked_files) if it isn't there yet.
append :linked_files, "config/master.key"
append :linked_dirs, "log", "tmp/pids", "tmp/cache"

after "deploy:publishing", "deploy:restart"

namespace :deploy do
  task :restart do
    on roles(:all) do
      execute "chmod 755 #{release_path}/public"
      # Restart Passenger
      execute "touch #{release_path}/tmp/restart.txt"
    end
  end
end
