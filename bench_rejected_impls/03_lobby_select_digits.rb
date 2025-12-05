require 'benchmark'

bench_candidates = []

bench_candidates << def array(banks, len)
  banks.sum { |digits|
    digits.each_with_object(Array.new(len + 1, 0)) { |d, best|
      len.downto(1) { |i|
        cand = best[i - 1] * 10 + d
        best[i] = cand if cand > best[i]
      }
    }[len]
  }
end

def largest_number(n, digits_after)
  return n.max if digits_after == 0

  max, i = n[...-digits_after].each_with_index.max_by(&:first)
  max * 10 ** digits_after + largest_number(n[(i + 1)..], digits_after - 1)
end

bench_candidates << def greedy_scan(banks, len)
  banks.sum { largest_number(it, len - 1) }
end

results = {}

banks = (ARGV.empty? ? DATA : ARGF).map { |line| line.chomp.chars.map(&method(:Integer)).freeze }.freeze

Benchmark.bmbm { |bm|
  bench_candidates.each { |f|
    bm.report(f) { 100.times { results[f] = send(f, banks, 12) } }
  }
}

# Obviously the benchmark would be useless if they got different answers.
if results.values.uniq.size != 1
  results.each { |k, v| puts "#{k} #{v}" }
  raise 'differing answers'
end
