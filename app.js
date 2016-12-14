var elasticsearch = require('elasticsearch');
var fs = require('fs');
var client = new elasticsearch.Client({
  host: '137.116.195.67:9200',
  log: 'trace'
});



metricsBody = {
    "size": 5000,
    "sort": [
        {
            "@timestamp": {
                "order": "desc",
                "unmapped_type": "boolean"
            }
        }
    ],
    "query": {
        "bool": {
            "must": [
                {
                    "query_string": {
                        "analyze_wildcard": true,
                        "query": "*"
                    }
                },
                {
                    "range": {
                        "@timestamp": {
                            "gte": 1481747400000,
                            "lte": 1481751000000,
                            "format": "epoch_millis"
                        }
                    }
                }
            ],
            "must_not": []
        }
    },
    "highlight": {
        "pre_tags": [
            "@kibana-highlighted-field@"
        ],
        "post_tags": [
            "@/kibana-highlighted-field@"
        ],
        "fields": {
            "*": {}
        },
        "require_field_match": false,
        "fragment_size": 2147483647
    },
    "aggs": {
        "2": {
            "date_histogram": {
                "field": "@timestamp",
                "interval": "1m",
                "time_zone": "Europe/Berlin",
                "min_doc_count": 1
            }
        }
    },
    "stored_fields": [
        "*"
    ],
    "_source": true,
    "script_fields": {},
    "fielddata_fields": [
        "@timestamp",
        "docker.container.created",
        "mongodb.status.local_time",
        "mongodb.status.background_flushing.last_finished",
        "postgresql.activity.backend_start",
        "postgresql.activity.transaction_start",
        "postgresql.activity.query_start",
        "postgresql.activity.state_change",
        "postgresql.bgwriter.stats_reset",
        "postgresql.database.stats_reset",
        "system.process.cpu.start_time"
    ]
};

logstashBody = {
    "size": 5000,
    "sort": [
        {
            "@timestamp": {
                "order": "desc",
                "unmapped_type": "boolean"
            }
        }
    ],
    "highlight": {
        "pre_tags": [
            "@kibana-highlighted-field@"
        ],
        "post_tags": [
            "@/kibana-highlighted-field@"
        ],
        "fields": {
            "*": {}
        },
        "require_field_match": false,
        "fragment_size": 2147483647
    },
    "query": {
        "bool": {
            "must": [
                {
                    "query_string": {
                        "query": "*",
                        "analyze_wildcard": true
                    }
                },
                {
                    "range": {
                        "@timestamp": {
                            "gte": 1481747400000,
                            "lte": 1481751000000,
                            "format": "epoch_millis"
                        }
                    }
                }
            ],
            "must_not": []
        }
    },
    "aggs": {
        "2": {
            "date_histogram": {
                "field": "@timestamp",
                "interval": "1m",
                "time_zone": "Europe/Berlin",
                "min_doc_count": 1
            }
        }
    },
    "stored_fields": [
        "*"
    ],
    "_source": true,
    "script_fields": {},
    "fielddata_fields": [
        "created",
        "@timestamp"
    ]
};


// // GET LOGSTASH INFO
// client.search({
//   index: 'logstash-*',
//   body: logstashBody
// }).then(function (resp) {
//     var hits = resp.hits.hits;
//     console.log(hits);
// }, function (err) {
//     console.trace(err.message);
// });



var allTitles = [];

// GET Metrics INFO
client.search({
  index: 'metricbeat-*',
  scroll: '30s', // keep the search results "scrollable" for 30 seconds
  body: metricsBody
}, function getMoreUntilDone(error, response) {

  // collect the title from each response
  response.hits.hits.forEach(function (hit) {
    allTitles.push(hit);
  });

  if (response.hits.total > allTitles.length) {
    // ask elasticsearch for the next set of hits from this search
    client.scroll({
      scrollId: response._scroll_id,
      scroll: '30s'
    }, getMoreUntilDone);
  } else {
    // console.log('every "test" title', allTitles);
    console.log("Amount of results: " + allTitles.length);
    fs.writeFile("out.json", allTitles);
  }
});
