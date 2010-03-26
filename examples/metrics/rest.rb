require 'rubygems'
require "restclient"

Metric(:http_get) do |http_get|
  http_get.monitors :url
  http_get.collects { RestClient.get(url) }
  http_get.reports(:status => :integer) {result.code}
  http_get.reports(:content) { result.body }
end

Monitor(:web) do
  http_get("http://opscode.com/") do |request|
    request.status.is equal_to 200
    # Hrm, maybe I need to give in and use #should...
    # request.content.at_selector('css-selector').matches "something"
  end
end