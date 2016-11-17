$LOAD_PATH.unshift File.dirname(__FILE__)
$stdout.sync = true
require 'v3'

run Rack::URLMap.new \
  "/" => StubApi.new
