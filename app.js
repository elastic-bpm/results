var elasticsearch = require('elasticsearch');
var fs = require('fs');
var moment = require('moment');
var client = new elasticsearch.Client({
    host: 'elk-host.westeurope.cloudapp.azure.com:9200',
    //  log: 'trace'
});

// var startEpoch = new Date("2017-05-26 22:37").valueOf();
// var endEpoch = new Date("2017-05-26 23:20").valueOf();
console.log("Getting logs from " + process.argv[2] + " to " + process.argv[3]);
var startEpoch = new Date(process.argv[2]).valueOf();
var endEpoch = new Date(process.argv[3]).valueOf();

metricsBody = {
    "version": true,
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
                            "gte": startEpoch,
                            "lte": endEpoch,
                            "format": "epoch_millis"
                        }
                    }
                }
            ],
            "must_not": []
        }
    },
    "_source": {
        "excludes": []
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
    "script_fields": {},
    "docvalue_fields": [
        "@timestamp",
        "container.created"
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
                            "gte": startEpoch,
                            "lte": endEpoch,
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

var outputFile = function (array, filename, callback) {
    var dateString = moment(startEpoch).format('YYYYMMDDHHmm');
    var dir = "./output/" + dateString;
    if (!fs.existsSync(dir)) {
        fs.mkdirSync(dir);
    }

    fs.writeFile(dir + "/" + filename + ".json", JSON.stringify(array, null, 2), callback);
};

var writeMetrics = function (callback) {
    var metricTitles = [];

    // GET Metrics INFO
    client.search({
        index: 'metricbeat-*',
        scroll: '30s', // keep the search results "scrollable" for 30 seconds
        body: metricsBody
    }, function getMoreUntilDone(error, response) {
        if (error) {
            console.error(error);
        } else {

            metricTitles.push.apply(metricTitles, response.hits.hits);

            if (response.hits.total > metricTitles.length) {
                console.log("Got " + metricTitles.length + " of " + response.hits.total);
                client.scroll({
                    scrollId: response._scroll_id,
                    scroll: '30s'
                }, getMoreUntilDone);
            } else {
                console.log("Amount of results for metrics: " + metricTitles.length);
                outputFile(metricTitles, "metrics", callback);
            }
        }
    });

};

var writeLogs = function (callback) {
    var logTitles = [];

    // GET logstash INFO
    client.search({
        index: 'logstash-*',
        scroll: '30s', // keep the search results "scrollable" for 30 seconds
        body: logstashBody
    }, function getMoreUntilDone(error, response) {
        if (error) {
            console.error(error);
        } else {
            logTitles.push.apply(logTitles, response.hits.hits);

            if (response.hits.total > logTitles.length) {
                console.log("Got " + logTitles.length + " of " + response.hits.total);
                client.scroll({
                    scrollId: response._scroll_id,
                    scroll: '30s'
                }, getMoreUntilDone);
            } else {
                console.log("Amount of results for logs: " + logTitles.length);
                outputFile(logTitles, "logstash", callback);
            }
        }
    });

};

writeMetrics(function () {
    writeLogs(function () {
        console.log("Done!");
    });
});
