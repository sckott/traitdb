require 'rubygems'
require "sinatra"
require "multi_json"
require "yaml"
require "sinatra/multi_route"
require "active_record"
require "redis"
require "mysql2"
require_relative 'model'
require_relative 'utils'

$config = YAML::load_file(File.join(__dir__, ENV['RACK_ENV'] == 'test' ? 'test_config.yaml' : 'config.yaml'))

ActiveRecord::Base.establish_connection($config['db'])

$redis = Redis.new host: ENV.fetch('REDIS_PORT_6379_TCP_ADDR', 'localhost'),
                   port: ENV.fetch('REDIS_PORT_6379_TCP_PORT', 6379)

class TraitDBApp < Sinatra::Application
  register Sinatra::MultiRoute

  not_found do
    halt 400, {'Content-Type' => 'application/json'}, MultiJson.dump({ 'error' => 'an error occurred' })
  end

  not_found do
    halt 404, {'Content-Type' => 'application/json'}, MultiJson.dump({ 'error' => 'route not found' })
  end

  error 500 do
    halt 500, {'Content-Type' => 'application/json'}, MultiJson.dump({ 'error' => 'server error' })
  end

  before do
    headers "Content-Type" => "application/json; charset=utf8"
    headers "Access-Control-Allow-Methods" => "HEAD, GET"
    headers "Access-Control-Allow-Origin" => "*"
    cache_control :public, :must_revalidate, :max_age => 300

    if $config['caching']
      @cache_key = Digest::MD5.hexdigest(request.url)
      if $redis.exists(@cache_key)
        headers 'Cache-Hit' => 'true'
        halt 200, $redis.get(@cache_key)
      end
    end
  end

  after do
    # cache response in redis
    if $config['caching'] && !response.headers['Cache-Hit'] && response.status == 200
      $redis.set(@cache_key, response.body[0], ex: $config['caching']['expires'])
    end
  end

  # prohibit certain methods
  route :put, :post, :delete, :copy, :options, :trace, '/*' do
    halt 405
  end

  get '/' do
    redirect '/heartbeat', 301
  end

  get "/heartbeat/?" do
    return MultiJson.dump({
      "routes" => [
        "/heartbeat",
        "/datasets",
        "/datasets/:datasetid",
        "/datasets/:datasetid/fields",
        "/datasets/:datasetid/fetch",
        "/datasets/:datasetid/search",
        "/search"
      ]
    })
  end

  get '/datasets/?' do
    datasets
  end

  get '/datasets/:id/?' do
    dataset
  end

  get '/datasets/:id/fields/?' do
    dataset_fields
  end

  get '/datasets/:id/fetch/?' do
    redirect s3_fetch, 301
  end

  # search methods, using elasticsearch
  get '/datasets/:id/search/?' do
    query
  end

  get '/search/?' do
    query
  end

end
