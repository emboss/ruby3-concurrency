require 'etc'
require 'benchmark'

NR_CORES = Etc.nprocessors
RANGE = 1..10_000
PARTITIONED = RANGE.group_by { |i| i % NR_CORES }.values.zip.flat_map { |it| it }

def prime?(n)
  n > 1 && (2...n).none? { |i| n % i == 0 }
end

def compute_primes
  NR_CORES.times.map do |i|
    Thread.new do
      partition = PARTITIONED[i]
      partition.each { |n| prime?(n) }
    end
  end.each(&:join)
end

def filter_primes
  result = []
  NR_CORES.times.map do |i|
    Thread.new do
      partition = PARTITIONED[i]
      partition.each { |n|
        # GIL verhindert Race Condition, aber z.B. nicht in JRuby
        result << n if prime?(n)
      }
    end
  end.each(&:join)
end

10.times do
  Benchmark.bm do |bm|
    bm.report("compute_primes") { compute_primes}
    bm.report("filter_primes") { filter_primes }
  end
end

