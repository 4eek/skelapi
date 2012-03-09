
# Performance test usage:

## Seed the database:
     thor database:seed development

## Launch the server:
     ./bin/server -sv -p 9000

## The auth info is returned in the headers:

    curl -vv -d '_apikey=i_am_busy' 'http://127.0.0.1:9000/status' ; echo

    ...snip...
    < X-RateLimit-MaxRequests: 1000
    < X-RateLimit-Requests: 999
    < X-RateLimit-Reset: 1312059600

## This user will hit the rate limit after 10 requests:

     for foo in 1 2 3 4 5 6 7 8 9 10 11 12 ; do echo -ne $foo "\t" ; curl -vv -d '_apikey=i_am_busy' 'http://127.0.0.1:9000/status' ; echo ; done

     ...
     11  [:error, "Your request rate (11) is over your limit (10)"]

## You can test the barrier (delays are in fractional seconds):

### auth_db_delay will fake a slow response from the mongo


    time curl -vv -d '_apikey=i_am_busy' -d 'auth_db_delay=0.3' 'http://127.0.0.1:9000/status'     
    ...
    X-Tracer: ... received_usage_info: 0.06, received_sleepy: 299.52, received_downstream_resp: 101.67, ..., total: 406.09
    ...
    real      0m0.416s        user    0m0.002s        sys     0m0.003s        pct     1.24

### This shows the mongodb response returning quickly, the fake DB delay returning after 300ms, and the downstream response returning after an additional 101 ms.

### The total request took 416ms of wall-clock time

### This will hold up even in the face of many concurrent connections.

### Relaunch in production:

    ./bin/server -sv -p 9000 -e prod

### On my laptop, with 20 concurrent requests:

    time ab -c20 -n20 -p 'status_post.body' -T 'application/json' 'http://127.0.0.1:9000/status'
    ...
    Percentage of the requests served within a certain time (ms)
    50%    431
    90%    457
    real      0m0.460s        user    0m0.001s        sys     0m0.003s        pct     0.85

### With 100 concurrent requests, the request latency starts to drop but the throughput and variance stand up:

    time ab -c100 -n100 -p 'status_post.body' -T 'application/json' 'http://127.0.0.1:9000/status'
    ...
    Percentage of the requests served within a certain time (ms)
    50%    640
    90%    673
    real      0m0.679s        user    0m0.002s        sys     0m0.007s        pct     1.33

