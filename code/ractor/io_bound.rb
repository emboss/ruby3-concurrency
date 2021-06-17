require 'net/http'
require 'uri'
require 'benchmark'

# Schlägt fehl, da net/http noch nicht für Ractor angepasst wurde
TIMES = 5

def http_get
  uri = URI.parse("https://www.ruby-lang.org")
  Net::HTTP.get_response(uri)
end

def http_get_ractor
  TIMES.times.map do
    Ractor.new do
      http_get
    end
  end.each(&:take)
end

10.times do
  puts Benchmark.measure {
    http_get_ractor
  }
end

