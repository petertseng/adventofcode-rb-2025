require_relative 'lib/union_find'

boxes = ARGF.map { |line|
  line.split(?,, 3).map(&method(:Integer)).freeze
}.freeze

id = boxes.each_with_index.to_h.freeze

uf = UnionFind.new((0...boxes.size).to_a, storage: Array)
target1 = boxes.size <= 20 ? 10 : 1000

boxes.combination(2).sort_by { |(x1, y1, z1), (x2, y2, z2)|
  (x1 - x2) ** 2 + (y1 - y2) ** 2 + (z1 - z2) ** 2
  # the zip is significantly slower:
  #p1.zip(p2).sum { (_1 - _2) ** 2 }
}.each_with_index { |(p1, p2), i|
  break puts p1[0] * p2[0] if uf.union(id[p1], id[p2]) == 1
  puts uf.sizes.max(3).reduce(:*) if i + 1 == target1
}
