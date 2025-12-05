require 'benchmark'

BIT = {
  ?@ => 1,
  ?. => 0,
  ?\n => 0,
}.freeze

# 1 bit for whether there's a paper towel there,
# 4 bits for a count with a max value of 8 (1000)
WIDTH = 5

bench_candidates = []

bench_candidates << def array_active(raw)
  width = nil
  towel = raw.each_line.flat_map { |row|
    # intentionally no chomp, using \n as an extra space to avoid wrapping
    width ||= row.size
    raise "inconsistent width #{row.size} != #{width}" if row.size != width

    row.each_char.map { it == ?@ }
  }

  dposes = [-width - 1, -width, -width + 1, -1, 1, width - 1, width, width + 1].freeze
  active = towel.each_with_index.filter_map { |c, i| i if c }.freeze
  orig_sz = active.size

  loop {
    remove = active.select { |pos|
      dposes.count { |dpos| pos + dpos >= 0 && towel[pos + dpos] } < 4
    }.freeze
    return orig_sz - towel.count(true) if remove.empty?
    remove.each { towel[it] = false }
    active = remove.flat_map { |rem|
      dposes.filter_map { |dpos| npos = rem + dpos; npos if npos >= 0 && towel[npos] }
    }.uniq.freeze
  }
end

bench_candidates << def hash_all(raw)
  towel = {}
  width = nil
  raw.each_line.with_index { |row, y|
    # intentionally no chomp, using \n as an extra space to avoid wrapping
    width ||= row.size
    raise "inconsistent width #{row.size} != #{width}" if row.size != width

    row.each_char.with_index { |c, x|
      towel[y * width + x] = true if c == ?@
    }
  }

  orig_sz = towel.size

  dposes = [-width - 1, -width, -width + 1, -1, 1, width - 1, width, width + 1].freeze

  loop {
    remove = towel.keys.select { |pos|
      dposes.count { |dpos| towel[pos + dpos] } < 4
    }.freeze
    return orig_sz - towel.size if remove.empty?
    remove.each { towel.delete(it) }
  }
end

bench_candidates << def hash_active(raw)
  towel = {}
  width = nil
  raw.each_line.with_index { |row, y|
    # intentionally no chomp, using \n as an extra space to avoid wrapping
    width ||= row.size
    raise "inconsistent width #{row.size} != #{width}" if row.size != width

    row.each_char.with_index { |c, x|
      towel[y * width + x] = true if c == ?@
    }
  }

  orig_sz = towel.size

  dposes = [-width - 1, -width, -width + 1, -1, 1, width - 1, width, width + 1].freeze
  active = towel.keys.freeze

  loop {
    remove = active.select { |pos|
      dposes.count { |dpos| towel[pos + dpos] } < 4
    }.freeze
    return orig_sz - towel.size if remove.empty?
    remove.each { towel.delete(it) }
    active = remove.flat_map { |rem|
      dposes.filter_map { |dpos| rem + dpos if towel[rem + dpos] }
    }.uniq.freeze
  }
end

bench_candidates << def set(raw)
  towel = Set.new
  width = nil
  raw.each_line.with_index { |row, y|
    # intentionally no chomp, using \n as an extra space to avoid wrapping
    width ||= row.size
    raise "inconsistent width #{row.size} != #{width}" if row.size != width

    row.each_char.with_index { |c, x|
      towel << y * width + x if c == ?@
    }
  }

  orig_sz = towel.size
  prev_sz = towel.size

  dposes = [-width - 1, -width, -width + 1, -1, 1, width - 1, width, width + 1].freeze

  loop {
    towel -= towel.select { |pos|
      dposes.count { |dpos| towel.include?(pos + dpos) } < 4
    }
    return orig_sz - prev_sz if towel.size == prev_sz
    prev_sz = towel.size
  }
end

def bits(raw, popcount)
  floor = 0
  width = nil

  raw.each_line { |line|
    # intentionally no chomp, using \n as an extra space to avoid wrapping
    width ||= line.size
    raise "inconsistent width #{line.size} != #{width}" if line.size != width

    line.each_char { |c|
      floor = floor << 5 | BIT.fetch(c)
    }
  }.freeze

  orig_towels = popcount[floor]

  shifts = [
    -width - 1,
    -width,
    -width + 1,
    -1,
    1,
    width - 1,
    width,
    width + 1,
  ].map { it * WIDTH }.freeze

  loop {
    count = floor << 1
    total = shifts.sum { count << it }

    eliminated = floor & ~(total >> 3) & ~(total >> 4)
    return orig_towels - popcount[floor] if eliminated == 0
    floor &= ~eliminated
  }
end

bench_candidates << def bits_popcount2(raw)
  bits(raw, ->x { x.to_s(2).count(?1) })
end

bench_candidates << def bits_popcount4(raw)
  bits(raw, ->x {
    v = x.to_s(4)
    v.count('12') + 2 * v.count(?3)
  })
end

bench_candidates << def bits_popcount8(raw)
  bits(raw, ->x {
    v = x.to_s(8)
    v.count('124') + 2 * v.count('356') + 3 * v.count(?7)
  })
end

bench_candidates << def bits_popcount16(raw)
  bits(raw, ->x {
    v = x.to_s(16)
    v.count('1248') + 2 * v.count('3569ac') + 3 * v.count('7bde') + 4 * v.count(?f)
  })
end

bench_candidates << def bits_popcount32(raw)
  bits(raw, ->x {
    v = x.to_s(32)
    v.count('1248g') + 2 * v.count('3569achiko') + 3 * v.count('7bdejlmpqs') + 4 * v.count('fnrtu') + 5 * v.count(?v)
  })
end

results = {}

raw = (ARGV.empty? ? DATA : ARGF).read.freeze

Benchmark.bmbm { |bm|
  bench_candidates.each { |f|
    bm.report(f) { 10.times { results[f] = send(f, raw) } }
  }
}

# Obviously the benchmark would be useless if they got different answers.
if results.values.uniq.size != 1
  results.each { |k, v| puts "#{k} #{v}" }
  raise 'differing answers'
end
