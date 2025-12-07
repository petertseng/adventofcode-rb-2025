require 'benchmark'

bench_candidates = []

bench_candidates << def beamwise(start, splitters)
  splits = 0

  tot = splitters.reduce({start => 1}) { |timelines, line|
    timelines.each_with_object(Hash.new(0)) { |(x, n), new_timelines|
      case line[x]
      when ?^
        splits += 1
        new_timelines[x - 1] += n
        new_timelines[x + 1] += n
      when ?.
        new_timelines[x] += n
      else raise "bad #{line[x]} at #{x} of #{line}"
      end
    }
  }.values.sum

  [splits, tot]
end

bench_candidates << def beamwise_skip(start, splitters)
  splits = 0

  tot = splitters.reduce({start => 1}) { |timelines, line|
    next timelines unless line.include?(?^)
    timelines.each_with_object(Hash.new(0)) { |(x, n), new_timelines|
      case line[x]
      when ?^
        splits += 1
        new_timelines[x - 1] += n
        new_timelines[x + 1] += n
      when ?.
        new_timelines[x] += n
      else raise "bad #{line[x]} at #{x} of #{line}"
      end
    }
  }.values.sum

  [splits, tot]
end

# Slightly faster, but can't handle splitters next to each other
bench_candidates << def beamwise_array_skip_unsafe(start, splitters)
  splits = 0

  beam = Array.new(splitters[0].size) { it == start ? 1 : 0 }
  final_active = splitters.reduce([start].freeze) { |actives, line|
    next actives unless line.include?(?^)
    actives.flat_map { |x|
      case line[x]
      when ?.; [x]
      when ?^
        splits += 1
        n = beam[x]
        beam[x] = 0
        # NB: Two splitters next to each other will clobber each others' values
        beam[x - 1] += n
        beam[x + 1] += n
        [x - 1, x + 1]
      else raise "bad #{line[x]} at #{x} of #{line}"
      end
    }.uniq.freeze
  }

  [splits, beam.values_at(*final_active).sum]
end

bench_candidates << def beamwise_array_skip_prefill(start, splitters)
  splits = 0

  width = splitters[0].size
  beam = Array.new(width) { it == start ? 1 : 0 }
  final_active = splitters.reduce([start].freeze) { |actives, line|
    next actives unless line.include?(?^)
    new_beam = Array.new(width, 0)
    actives.flat_map { |x|
      case line[x]
      when ?.
        new_beam[x] += beam[x]
        [x]
      when ?^
        splits += 1
        n = beam[x]
        new_beam[x - 1] += n
        new_beam[x + 1] += n
        [x - 1, x + 1]
      else raise "bad #{line[x]} at #{x} of #{line}"
      end
    }.uniq.freeze.tap { beam = new_beam.freeze }
  }

  [splits, beam.values_at(*final_active).sum]
end

bench_candidates << def beamwise_array_skip_or(start, splitters)
  splits = 0

  beam = [].tap { it[start] = 1 }
  final_active = splitters.reduce([start].freeze) { |actives, line|
    next actives unless line.include?(?^)
    new_beam = []
    actives.flat_map { |x|
      case line[x]
      when ?.
        new_beam[x] = (new_beam[x] || 0) + beam[x]
        [x]
      when ?^
        splits += 1
        n = beam[x]
        new_beam[x - 1] = (new_beam[x - 1] || 0) + n
        new_beam[x + 1] = (new_beam[x + 1] || 0) + n
        [x - 1, x + 1]
      else raise "bad #{line[x]} at #{x} of #{line}"
      end
    }.uniq.freeze.tap { beam = new_beam.freeze }
  }

  [splits, beam.values_at(*final_active).sum]
end

bench_candidates << def splitterwise_each_array_unsafe(start, splitters)
  splits = 0

  beam = Array.new(splitters[0].size) { it == start ? 1 : 0 }

  splitters.each { |row|
    row.chomp.each_char.with_index { |c, x|
      case c
      when ?. # OK
      when ?^
        next unless (n = beam[x]) > 0
        splits += 1
        beam[x] -= n
        # NB: Two splitters next to each other will clobber each others' values
        beam[x - 1] += n
        beam[x + 1] += n
      else raise "bad #{c} at #{x} of #{row}" if c != ?^
      end
    }
  }

  [splits, beam.sum]
end

bench_candidates << def splitterwise_index_or(start, splitters)
  splits = 0

  final_beam = splitters.reduce({start => 1}) { |beam, row|
    x = -1
    new_beam = beam.dup
    while (x = row.index(?^, x + 1))
      next unless (n = beam[x]) &.> 0

      splits += 1
      new_beam[x] -= n
      new_beam[x - 1] = (new_beam[x - 1] || 0) + n
      new_beam[x + 1] = (new_beam[x + 1] || 0) + n
    end
    new_beam
  }

  [splits, final_beam.values.sum]
end

bench_candidates << def splitterwise_index_or_delete_unsafe(start, splitters)
  splits = 0

  final_beam = splitters.reduce({start => 1}) { |beam, row|
    x = -1
    new_beam = beam.dup
    while (x = row.index(?^, x + 1))
      next unless (n = beam[x])

      splits += 1
      # If two splitters are next to each other, should only delete if new value == 0
      new_beam.delete(x)
      new_beam[x - 1] = (new_beam[x - 1] || 0) + n
      new_beam[x + 1] = (new_beam[x + 1] || 0) + n
    end
    new_beam
  }

  [splits, final_beam.values.sum]
end

bench_candidates << def splitterwise_index_default(start, splitters)
  splits = 0

  final_beam = splitters.reduce(Hash.new(0).merge(start => 1)) { |beam, row|
    x = -1
    new_beam = beam.dup
    while (x = row.index(?^, x + 1))
      next unless (n = beam[x]) > 0

      splits += 1
      new_beam[x] -= n
      new_beam[x - 1] += n
      new_beam[x + 1] += n
    end
    new_beam
  }

  [splits, final_beam.values.sum]
end

bench_candidates << def splitterwise_index_array(start, splitters)
  splits = 0

  final_beam = splitters.reduce(Array.new(splitters.map(&:size).max) { it == start ? 1 : 0 }) { |beam, row|
    x = -1
    new_beam = beam.dup
    while (x = row.index(?^, x + 1))
      next unless (n = beam[x]) > 0
      splits += 1
      new_beam[x] -= n
      new_beam[x - 1] += n
      new_beam[x + 1] += n
    end
    new_beam
  }

  [splits, final_beam.sum]
end

bench_candidates << def splitterwise_index_array_unsafe(start, splitters)
  splits = 0

  beam = Array.new(splitters[0].size) { it == start ? 1 : 0 }

  splitters.each { |row|
    x = -1
    while (x = row.index(?^, x + 1))
      next unless (n = beam[x]) > 0
      splits += 1
      beam[x] -= n
      # NB: Two splitters next to each other will clobber each others' values
      beam[x - 1] += n
      beam[x + 1] += n
    end
  }

  [splits, beam.sum]
end

start = ARGF.readline.then {
  raise "line 0 #{s_line} should only have S" unless it.match?(/^\.*S\.*$/)
  it.index(?S)
}

splitters = ARGF.map(&:freeze).freeze

results = {}

Benchmark.bmbm { |bm|
  bench_candidates.each { |f|
    bm.report(f) { 100.times { results[f] = send(f, start, splitters) } }
  }
}

# Obviously the benchmark would be useless if they got different answers.
if results.values.uniq.size != 1
  results.each { |k, v| puts "#{k} #{v}" }
  raise 'differing answers'
end
