## Sample Nginx Status Page
## Nginx config:
#  location /nginx_status {
#    stub_status on;
#    access_log   off;
#    allow 127.0.0.1;
#    deny all;
#  }
# > curl -k https://127.0.0.1/nginx_status/
## Output:
# Active connections: 6
# server accepts handled requests
#  31247198 31247198 31344041     # accepted connections, handled connections, requests
# Reading: 1 Writing: 5 Waiting: 0

require 'typhoeus'

Metric(:nginx_requests) do

  monitors(:status_url, :validate => /\/.*/, :required => true)

  collects do
    req = Typhoeus::Request.get(status_url)
    if req.success?
      req.body
    else
      report.collection_failed(req)
    end
  end


  reports(:prior_nginx_stats) do
    #accepted, handled, requests
    stash.load
  end

  reports(:current_nginx_stats) do
    accepted, handled, requests = result.line(2).scan(/[\d]+/).map(&:to_i)
    stash.save( {:timestamp => Time.now.utc.to_i, :data => [ accepted, handled, requests ] } )
  end

  reports(:request_counter) do
    current_nginx_stats[:data][2]
  end

  reports(:requests_per_second => :float) do
    if prior_nginx_stats.nil?
      nil
    else
      request_delta = current_nginx_stats[:data][2] - prior_nginx_stats[:data][2]
      time_delta = current_nginx_stats[:timestamp] - prior_nginx_stats[:timestamp]
      request_delta = request_delta.fdiv(time_delta)
    end
  end

end

