require 'net/http'
require 'uri'
require 'benchmark'

TIMES = 5

def http_get
  uri = URI.parse("https://www.ruby-lang.org")
  Net::HTTP.get_response(uri)
end

def http_get_proc
  TIMES.times do
    fork do
      http_get
    end
  end
  Process.waitall
end

10.times do
  puts Benchmark.measure {
    http_get_proc
  }
end

