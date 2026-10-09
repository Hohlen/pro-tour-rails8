# Must match the capistrano version pinned in the Gemfile.
lock "~> 3.20.1"

# Same deploy directory name as legacy pro-tour-v2.0 (/home/admin/protourfantasygolf.com), but on the new server for
# the Rails 8 apps -- not legacy's VPS.
application = "protourfantasygolf.com"
set :application, application

set :repo_url, "git@github.com:Hohlen/pro-tour-rails8.git"
set :branch, "main"

# The server pulls from GitHub using the deploying workstation's SSH key.
# https://docs.github.com/en/developers/overview/managing-deploy-keys#ssh-agent-forwarding
set :ssh_options, { forward_agent: true }
set :pty, true

set :format, :airbrussh
set :log_level, :info # :debug

set :rvm_ruby_version, "3.4.11"
set :deploy_to, "/home/admin/#{application}"
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
      execute "chown admin:nobody #{release_path} -R"
      # Restart Passenger
      execute "touch #{release_path}/tmp/restart.txt"
    end
  end
end
