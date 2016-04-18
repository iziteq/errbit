require 'singleton'
require 'fileutils'
require 'redis'

class DaemonStatus

  QUEUE_LIMIT         = 30
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

    # It's unlikely that we'll reach this limit
    # Suppose we've done it, then fail status endpoint and restart errbit manually
    return false if current_lpop_count >= COMMANDSTATS_LIMIT

    alive = first_run? || daemon_is_working?(current_lpop_count) || queue_is_empty?

    # we have to increase througput of the queue processor
    # so, notify about it by failing
    alive = false unless queue_has_allowed_length?
    
    @prev_lpop_count = current_lpop_count
    alive
  end

  private

    def queue_has_allowed_length?
      queue_size =  redis.llen(redis_config['key'])
      queue_size < QUEUE_LIMIT
    end

    def queue_is_empty?
      redis.llen(redis_config['key']) == 0
    end

    def daemon_is_working?(current_lpop_count)
      # if lpop count is increasing, we consider that the daemon does it
      @prev_lpop_count < current_lpop_count
    end

    def get_lpop_count
      redis.info(:commandstats)['lpop']['calls'].to_i
    end

    def first_run?
      @prev_lpop_count.nil?
    end

    def redis_config
      @config['redis']
    end
end
