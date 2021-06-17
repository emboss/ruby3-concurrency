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
    Ractor.new(PARTITIONED[i]) do |partition|
      partition.each { |n| prime?(n) }
      nil # implicit return value
    end
  end.each(&:take)
end

def filter_primes
  NR_CORES.times.map do |i|
    Ractor.new(PARTITIONED[i]) do |partition|
      Ractor.yield(partition.filter { |n|
        prime?(n)
      })
    end
  end.flat_map(&:take)
end

10.times do
  Benchmark.bm do |bm|
    bm.report("compute_primes") { compute_primes}
    bm.report("filter_primes") { filter_primes }
  end
end

