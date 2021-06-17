require 'etc'
require 'benchmark'

NR_CORES = Etc.nprocessors
RANGE = 1..10_000
PARTITIONED = RANGE.group_by { |i| i % NR_CORES }.values.zip.flat_map { |it| it }

def prime?(n)
  n > 1 && (2...n).none? { |i| n % i == 0 }
end

def compute_primes
  NR_CORES.times do |i|
    fork do
      partition = PARTITIONED[i]
      partition.each { |n| prime?(n) }
    end
  end
  Process.waitall
end

def filter_primes
  result = []
  pipes = []
  pids = []

  NR_CORES.times do |i|
    reader, writer = IO.pipe

    pid = fork do
      reader.close
      partition = PARTITIONED[i]
      partition.select { |n|
        prime?(n)
      }.each { |prime|
        writer.write("#{prime}\n")
      }
    end
    writer.close
    pids << pid
    pipes << reader
  end

  pipes.each do |pipe|
    primes = pipe.read
    pipe.close
    result.concat(primes.split("\n").map(&:to_i))
  end

  pids.each do |pid|
    Process.waitpid(pid)
  end
end

10.times do
  Benchmark.bm do |bm|
    bm.report("compute_primes") { compute_primes }
    bm.report("filter_primes") { filter_primes }
  end
end

