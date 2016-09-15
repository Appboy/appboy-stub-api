$LOAD_PATH.unshift File.dirname(__FILE__)
require 'v3'

run Rack::URLMap.new \
  "/" => StubApi.new
