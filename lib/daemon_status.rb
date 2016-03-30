require 'singleton'
require 'fileutils'
require 'redis'

class DaemonStatus

  QUEUE_LIMIT         = 1000
  COMMANDSTATS_LIMIT = 1_000_000_000

  include Singleton

  def initialize
    @config = YAML.load(File.read(Rails.root.join('config', 'daemon_config.yml')))
  end

  def redis
    @redis ||= Redis.new(host: redis_config['host'], port: redis_config['port'])
  end

  def alive?
    current_lpop_count = get_lpop_count
    return false if current_lpop_count >= COMMANDSTATS_LIMIT

    if !is_first_run? && (!queue_clearing?(current_lpop_count) || queue_overflow?)
      @prev_lpop_count   = current_lpop_count
      false
    else
      @prev_lpop_count   = current_lpop_count
      true
    end
  end

  private

    def reset_stat
      @redis.info(:resetstat)
      @prev_lpop_count = nil
    end

    def queue_size
      redis.llen(redis_config['key'])
    end

    def queue_overflow?
      queue_size >= QUEUE_LIMIT
    end

    def queue_clearing?(current_lpop_count)
      @prev_lpop_count < current_lpop_count
    end

    def get_lpop_count
      redis.info(:commandstats)['lpop']['calls'].to_i
    end

    def is_first_run?
      @prev_lpop_count.nil?
    end

    def redis_config
      @config['redis']
    end
end