require_relative '../lib/heap'
require_relative '../lib/union_find'

require 'benchmark'

bench_candidates = []

bench_candidates << def array_sort(boxes)
  id = boxes.each_with_index.to_h.freeze

  uf = UnionFind.new((0...boxes.size).to_a, storage: Array)

  boxes.combination(2).sort_by { |(x1, y1, z1), (x2, y2, z2)|
    (x1 - x2) ** 2 + (y1 - y2) ** 2 + (z1 - z2) ** 2
  }.each { |p1, p2|
    return [p1, p2] if uf.union(id[p1], id[p2]) == 1
  }
  raise 'never became one'
end

bench_candidates << def array_sort_zip(boxes)
  id = boxes.each_with_index.to_h.freeze

  uf = UnionFind.new((0...boxes.size).to_a, storage: Array)

  boxes.combination(2).sort_by { |p1, p2|
    p1.zip(p2).sum { (_1 - _2) ** 2 }
  }.each { |p1, p2|
    return [p1, p2] if uf.union(id[p1], id[p2]) == 1
  }
  raise 'never became one'
end

bench_candidates << def array_heap(boxes)
  id = boxes.each_with_index.to_h.freeze

  min_pair = Heap.new(boxes.combination(2).map { |p1, p2|
    x1, y1, z1 = p1
    x2, y2, z2 = p2
    [(x1 - x2) ** 2 + (y1 - y2) ** 2 + (z1 - z2) ** 2, p1, p2].freeze
  })

  uf = UnionFind.new((0...boxes.size).to_a, storage: Array)

  while (_, pos1, pos2 = min_pair.pop)
    return [pos1, pos2] if uf.union(id[pos1], id[pos2]) == 1
  end
  raise 'never became one'
end

bench_candidates << def array_heap_zip(boxes)
  id = boxes.each_with_index.to_h.freeze

  min_pair = Heap.new(boxes.combination(2).map { |p1, p2|
    [p1.zip(p2).sum { (_1 - _2) ** 2 }, p1, p2]
  })

  uf = UnionFind.new((0...boxes.size).to_a, storage: Array)

  while (_, pos1, pos2 = min_pair.pop)
    return [pos1, pos2] if uf.union(id[pos1], id[pos2]) == 1
  end
  raise 'never became one'
end

bench_candidates << def hash_sort(boxes)
  uf = UnionFind.new(boxes)

  boxes.combination(2).sort_by { |(x1, y1, z1), (x2, y2, z2)|
    (x1 - x2) ** 2 + (y1 - y2) ** 2 + (z1 - z2) ** 2
  }.each { |p1, p2|
    return [p1, p2] if uf.union(p1, p2) == 1
  }
  raise 'never became one'
end

bench_candidates << def hash_heap(boxes)
  min_pair = Heap.new(boxes.combination(2).map { |p1, p2|
    x1, y1, z1 = p1
    x2, y2, z2 = p2
    [(x1 - x2) ** 2 + (y1 - y2) ** 2 + (z1 - z2) ** 2, p1, p2].freeze
  })

  uf = UnionFind.new(boxes)

  while (_, pos1, pos2 = min_pair.pop)
    return [pos1, pos2] if uf.union(pos1, pos2) == 1
  end
  raise 'never became one'
end

boxes = ARGF.map { |line|
  line.split(?,, 3).map(&method(:Integer)).freeze
}.freeze

results = {}

Benchmark.bmbm { |bm|
  bench_candidates.each { |f|
    bm.report(f) { 3.times { results[f] = send(f, boxes) } }
  }
}

# Obviously the benchmark would be useless if they got different answers.
if results.values.uniq.size != 1
  results.each { |k, v| puts "#{k} #{v}" }
  raise 'differing answers'
end
