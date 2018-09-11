directory '/var/www/iziteq/errbit/current'
rackup "/var/www/iziteq/errbit/current/config.ru"
environment 'production'

pidfile "/var/www/iziteq/errbit/shared/tmp/pids/puma.pid"
state_path "/var/www/iziteq/errbit/shared/tmp/pids/puma.state"
stdout_redirect '/var/www/iziteq/errbit/shared/log/puma_access.log', '/var/www/iziteq/errbit/shared/log/puma_error.log', true

threads 0,16

bind 'unix:///var/www/iziteq/errbit/shared/tmp/sockets/puma.sock'

workers 1

activate_control_app