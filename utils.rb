require "yaml"
require "elasticsearch"
require 'aws-sdk'
require "multi_json"

$config = YAML::load_file(File.join(__dir__, ENV['RACK_ENV'] == 'test' ? 'test_config.yaml' : 'config.yaml'))

$esclient = Elasticsearch::Client.new url: 'http://localhost:9200'

creds = Aws::Credentials.new(ENV['AWS_S3_BERK_WRITE_ACCESS_KEY'], ENV['AWS_S3_BERK_WRITE_SECRET_KEY'])
client = Aws::S3::Client.new(region: 'us-west-2', credentials: creds)
$signer = Aws::S3::Presigner.new(client: client)

def datasets
  begin
    data = TDBDatasets.endpoint(params)
  raise Exception.new('no results found') if data.length.zero?
    { matched: data.limit(nil).count(1), returned: data.length, data: data, error: nil }.to_json
  rescue Exception => e
    halt 400, err_body(e)
  end
end

def dataset
  begin
    data = TDBDataset.endpoint(params)
  raise Exception.new('no results found') if data.length.zero?
    { matched: data.limit(nil).count(1), returned: data.length, data: data, error: nil }.to_json
  rescue Exception => e
    halt 400, err_body(e)
  end
end

def dataset_fields
  begin
    data = TDBFields.endpoint(params)
  raise Exception.new('no results found') if data.length.zero?
    { matched: data.limit(nil).count(1), returned: data.length, data: data, error: nil }.to_json
  rescue Exception => e
    halt 400, err_body(e)
  end
end

def query
  begin
    data = elastic_query
  raise Exception.new('no results found') if data['hits']['hits'].length == 0
    if data['hits']['hits'][0]['_source'].nil?
      dd = data['hits']['hits'].collect { |x| x['fields'] }
    else
      dd = data['hits']['hits'].collect { |x| x['_source'] }
    end
    { found: data['hits']['total'],
      max_score: data['hits']['max_score'],
      returned: data['hits']['hits'].length,
      data: dd,
      error: nil }.to_json
  rescue Exception => e
    halt 400, err_body(e)
  end
end

def elastic_query
  if params["id"]
    path = "tdb" + params["id"]
  else
    path = "tdb*"
  end
  %i(limit offset).each do |p|
    unless params[p].nil?
      begin
        params[p] = Integer(params[p])
      rescue ArgumentError
        raise Exception.new("#{p.to_s} is not an integer")
      end
    end
  end
  lim = params["limit"] || 200
  offset = params["offset"] || 0
  fields = params["fields"] || nil
  query = params["q"] || {}
  return es_search(path, lim, offset, query, fields)
end

def es_search(index, limit, offset, query = {}, fields = nil)
  if fields.nil?
    $esclient.search index: index, size: limit, from: offset, q: query
  else
    $esclient.search index: index, size: limit, from: offset, q: query, fields: fields
  end
end

def err_body(e)
  return { found: 0, returned: 0, data: nil, error: { message: e.message }}.to_json
end

def s3_fetch
  id = params["id"]
  return $signer.presigned_url(:get_object, bucket: 'traitdbz', key: id + '.csv', expires_in: 3600)
end
