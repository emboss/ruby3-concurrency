require 'net/http'
require 'uri'
require 'fiber'
require 'async'
require 'async/barrier'
require 'async/http'
require 'benchmark'

TIMES = 5

def http_get
  uri = URI.parse("https://www.ruby-lang.org")
  Net::HTTP.get_response(uri)
end

def http_get_non_blocking
  Async do
    url = Async::HTTP::Endpoint.parse("https://www.ruby-lang.org")
    client = Async::HTTP::Client.new(url)
    barrier = Async::Barrier.new

    TIMES.times do
      barrier.async do
        client.get("/").finish
      end
    end
    barrier.wait
  ensure
    client&.close
  end
end

def http_get_fiber_scheduler
  Async do
    TIMES.times do
      Fiber.schedule do
        http_get
      end
    end
  end.wait
end

10.times do
  Benchmark.bm do |bm|
    bm.report("http_get_fiber_scheduler") { http_get_fiber_scheduler }
    bm.report("http_get_non_blocking") { http_get_non_blocking }
  end
end

