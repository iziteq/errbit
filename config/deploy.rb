# Deploy Config
# =============
#
# Copy this file to config/deploy.rb and customize it as needed.
# Then run `cap errbit:setup` to set up your server and finally
# `cap deploy` whenever you would like to deploy Errbit. Refer
# to ./docs/deployment/capistrano.md for more info

# config valid only for current version of Capistrano
lock '3.4.1'

set :application, 'errbit'
set :repo_url, 'https://github.com/iziteq/errbit.git'
set :branch, ENV['branch'] || 'izi_master'
set :deploy_to, '/var/www/iziteq/errbit'
set :keep_releases, 5

set :pty, true
set :ssh_options, forward_agent: true

set :rbenv_type, :user # or :system, depends on your rbenv setup
set :rbenv_ruby, '2.4.2'

set :linked_files, fetch(:linked_files, []) + %w(
  .env
  config/newrelic.yml
  config/puma.rb
  config/daemon_config.yml
  public/javascripts/notifier.js
)

set :linked_dirs, fetch(:linked_dirs, []) + %w(
  log
  tmp/cache tmp/pids tmp/sockets
  vendor/bundle
)

# check out capistrano-rbenv documentation
# set :rbenv_type, :system
# set :rbenv_path, '/usr/local/rbenv'
# set :rbenv_ruby, File.read(File.expand_path('../../.ruby-version', __FILE__)).strip
# set :rbenv_roles, :all

namespace :errbit do
  desc "Set up config files (first time setup)"
  task :setup do
    on roles(:app) do
      execute "mkdir -p #{shared_path}/config"
      execute "mkdir -p #{shared_path}/tmp/pids"
      execute "touch #{shared_path}/.env"

      {
        'config/newrelic.example.yml' => 'config/newrelic.yml'
      }.each do |src, target|
        unless test("[ -f #{shared_path}/#{target} ]")
          upload! src, "#{shared_path}/#{target}"
        end
      end

      invoke 'puma:config'
    end
  end
end

namespace :db do
  desc "Create and set up the mongo db"
  task :setup do
    on roles(:db) do
      within current_path do
        with rails_env: fetch(:rails_env) do
          execute :rake, 'errbit:bootstrap'
        end
      end
    end
  end
end

set :puma_user, fetch(:user)
set :puma_rackup, -> { File.join(current_path, 'config.ru') }
set :puma_state, "#{shared_path}/tmp/pids/puma.state"
set :puma_pid, "#{shared_path}/tmp/pids/puma.pid"
set :puma_bind, "unix://#{shared_path}/tmp/sockets/puma.sock"    #accept array for multi-bind
set :puma_control_app, false
set :puma_access_log, "#{shared_path}/log/puma_access.log"
set :puma_error_log, "#{shared_path}/log/puma_error.log"
set :puma_role, :app
set :puma_env, fetch(:rack_env, fetch(:rails_env, 'production'))
set :puma_threads, [0, 16]
set :puma_workers, 0
set :puma_worker_timeout, nil
set :puma_init_active_record, false
set :puma_preload_app, false
set :puma_daemonize, false
set :puma_plugins, []  #accept array of plugins
set :puma_tag, fetch(:application)
set :puma_restart_command, 'bundle exec puma'