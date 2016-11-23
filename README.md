Trait database API
==================

Lots of open trait data is available on the web. However, there is a filtering problem: the data is scattered over lots of different journals supplementary info pages, and in different data repositories like Dryad, that it becomes hard to find what you want.

I thought it would make sense to try to collate open trait data in one place, allow fetching of individual datasets, searching across datasets, and even fetching trait data across datasets.

There are single places to look for trait data, e.g., TRY, but I am fundamentally against these types of repositories that require asking permission for use. It's bad for science.

## Under the hood

* API: Ruby/Sinatra
* Storage: MySQL
* Search: ...
* Caching: Redis
  * each key cached for 3 hours
* Server: Caddy
  * https
* Authentication: none

## API

* root path <https://traits.party> - redirects to `/heartbeat`
* `/heartbeat`

```r
{
    "routes": [
        "/heartbeat",
        "/datasets",
        "/datasets/:datasetid",
        "/datasets/:datasetid/fields",
        "/datasets/:datasetid/fetch",
        "/datasets/:datasetid/search",
        "/search"
    ]
}
```

* `/datastets` - list datasets and minimal metadata
* `/datasets/:datasetid` - dataset metadata
* `/datasets/:datasetid/fields` - dataset fields
* `/datasets/:datasetid/fetch` - fetch entire dataset from Amazon S3
* `/datasets/:datasetid/search` - search on a specific dataset - not avail. yet
* `/search` - search across datasets - not avail. yet
