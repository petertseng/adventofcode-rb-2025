require 'benchmark'

bench_candidates = []

bench_candidates << def baseline(points, width, outside, idx, idy)
  points.combination(2).filter_map { |(x1, y1), (x2, y2)|
    l = idx[[x1, x2].min]
    r = idx[[x1, x2].max]
    top = idy[[y1, y2].min]
    bot = idy[[y1, y2].max]

    next if (top..bot).any? { |y|
      outside[y * width + l] || outside[y * width + r]
    }
    next if (l..r).any? { |x|
      outside[top * width + x] || outside[bot * width + x]
    }

    ((x1 - x2).abs + 1) * ((y1 - y2).abs + 1)
  }.max
end

bench_candidates << def preflight_area(points, width, outside, idx, idy)
  max = 0
  points.combination(2) { |(x1, y1), (x2, y2)|
    area = ((x1 - x2).abs + 1) * ((y1 - y2).abs + 1)
    next if area <= max

    l = idx[[x1, x2].min]
    r = idx[[x1, x2].max]
    top = idy[[y1, y2].min]
    bot = idy[[y1, y2].max]

    next if (top..bot).any? { |y|
      outside[y * width + l] || outside[y * width + r]
    }
    next if (l..r).any? { |x|
      outside[top * width + x] || outside[bot * width + x]
    }

    max = area
  }
  max
end

bench_candidates << def preflight_corners(points, width, outside, idx, idy)
  max = 0
  points.combination(2) { |(x1, y1), (x2, y2)|
    area = ((x1 - x2).abs + 1) * ((y1 - y2).abs + 1)
    next if area <= max

    l = idx[[x1, x2].min]
    r = idx[[x1, x2].max]
    top = idy[[y1, y2].min]
    bot = idy[[y1, y2].max]

    next if outside[top * width + l]
    next if outside[top * width + r]
    next if outside[bot * width + l]
    next if outside[bot * width + r]

    next if (top..bot).any? { |y|
      outside[y * width + l] || outside[y * width + r]
    }
    next if (l..r).any? { |x|
      outside[top * width + x] || outside[bot * width + x]
    }

    max = area
  }
  max
end

bench_candidates << def sort_by_area(points, width, outside, idx, idy)
  points.combination(2).map { |v|
    ((x1, y1), (x2, y2)) = v
    [((x1 - x2).abs + 1) * ((y1 - y2).abs + 1), v]
  }.sort_by(&:first).reverse_each { |area, ((x1, y1), (x2, y2))|
    l = idx[[x1, x2].min]
    r = idx[[x1, x2].max]
    top = idy[[y1, y2].min]
    bot = idy[[y1, y2].max]

    next if (top..bot).any? { |y|
      outside[y * width + l] || outside[y * width + r]
    }
    next if (l..r).any? { |x|
      outside[top * width + x] || outside[bot * width + x]
    }
    return area
  }
end

points = ARGF.map { |line|
  line.split(?,, 2).map(&method(:Integer)).freeze
}.freeze

xs = points.map(&:first).sort.uniq.freeze
ys = points.map(&:last).sort.uniq.freeze

idx = xs.each_with_index.to_h.freeze
idy = ys.each_with_index.to_h.freeze

width = xs.size
height = ys.size

green = Array.new(height * width)
outside = Array.new(height * width)

(points + [points[0]]).each_cons(2) { |(x1, y1), (x2, y2)|
  top = idy.fetch([y1, y2].min)
  bottom = idy.fetch([y1, y2].max)
  left = idx.fetch([x1, x2].min)
  right = idx.fetch([x1, x2].max)

  (top..bottom).each { |y|
    (left..right).each { |x| green[y * width + x] = true }
  }
}

outer_nils = ((0...height).flat_map { |y|
  [
    y * width,
    y * width + width - 1,
  ]
} + (0...width).flat_map { |x|
  [
    x,
    (height - 1) * width + x,
  ]
}).reject { |pos| green[pos] }

# row wrapping doesn't matter, outside will always be already visited
dposes = [-width, -1, 1, width].freeze

q = outer_nils
while pos = q.shift
  dposes.each { |dpos|
    npos = pos + dpos
    next if npos < 0
    next if npos >= height * width
    next if green[npos]
    next if outside[npos]
    outside[npos] = true
    q << npos
  }
end

results = {}

Benchmark.bmbm { |bm|
  bench_candidates.each { |f|
    bm.report(f) { 3.times { results[f] = send(f, points, width, outside, idx, idy) } }
  }
}

# Obviously the benchmark would be useless if they got different answers.
if results.values.uniq.size != 1
  results.each { |k, v| puts "#{k} #{v}" }
  raise 'differing answers'
end
