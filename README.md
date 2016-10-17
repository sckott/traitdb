Trait database API
==================

THIS IS NOT UP YET - WILL UPDATE README WHEN IT IS

Lots of open trait data is available on the web. However, there is a filtering problem: the data is scattered over lots of different journals supplementary info pages, and in different data repositories like Dryad, that it becomes hard to find what you want.

I thought it would make sense to try to collate open trait data in one place, allow fetching of individual datasets, searching across datasets, and even fetching trait data across datasets.

There are single places to look for trait data, e.g., TRY, but I am fundamentally against these types of repositories that require asking permission for use. It's bad for science.

## Under the hood

* API: Ruby/Sinatra
* Storage: PostgreSQL
* Search: Elasticsearch
* Caching: Redis
  * each key cached for 3 hours
* Server: Caddy
  * https
* Authentication: none

## Examples

```
body = {
  :selector => {
    :_id => {
      :$gt => nil
    }
  }
}

out = conn.post do |req|
  req.url "/%s/_find" % params["id"]
  req.headers['Content-Type'] = 'application/json'
  req.body = MultiJson.dump(body)
end
```

```
curl -v -H "Content-Type: application/json" -XPOST 'http://localhost:8877/dataset/cab859b90-020a-418b-80fc-b7492378e92' -d '{"selector":{"genus":"Rhipidura"},"limit":3}' | jq .
```


```
curl -v -XPOST -H "Content-Type: application/json"  'http://localhost:8877/dataset/cab859b90-020a-418b-80fc-b7492378e92/search' -d '{
    "aggs":{
        "bodysizes":{
            "histogram":{
                "field":"adult_body_mass_g",
                "interval":200
            }
        }
    }
}'| jq .
```


