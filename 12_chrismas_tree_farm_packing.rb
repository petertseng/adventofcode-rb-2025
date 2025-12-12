BIT = {
  ?# => 1,
  ?. => 0,
}.freeze

slow = ARGV.delete('-s') || ARGV.delete('--slow')

def present(s)
  basic = s.split(?:, 2)[1].chars.reduce(0) { |acc, c|
    c == ?\n ? acc : (acc << 1 | BIT[c])
  }
  [basic, fliph(basic)].uniq.flat_map { |n0|
    [n0, n1 = cw(n0), n2 = cw(n1), n3 = cw(n2)]
  }.uniq.freeze
end

def fliph(n)
  # 876
  # 543
  # 210
  # becomes
  # 678
  # 345
  # 012
  right = 0b001001001
  mid   = 0b010010010
  left  = 0b100100100
  (n & right) << 2 | (n & left) >> 2 | n & mid
end

def cw(n)
  # 876
  # 543
  # 210
  # becomes
  # 258
  # 147
  # 036
  [2, 5, 8, 1, 4, 7, 0, 3, 6].each_with_index.sum { |dest, src| n[src] << dest }
end

def fit?(presents, needs, w, h, free, i)
  return true unless need = needs[i]
  variants = presents.fetch(need)
  variants.any? { |variant|
    remain = free
    cand = variant
    j = -1
    while remain >= variant
      # assumed width of exactly 3 (otherwise it will miss some placements)
      if (j += 1) % w + 2 < w && free & cand == cand
        return true if fit?(presents, needs, w, h, free & ~cand, i + 1)
      end
      cand <<= 1
      remain >>= 1
    end
  }
end

def expand(n, width)
  dwidth = width - 3
  row1 = n & 0b111
  row2 = n & 0b111000
  row3 = n & 0b111000000
  row1 | row2 << dwidth | row3 << (dwidth * 2)
end

def fmt(n, w = 3)
  3.times.map { |y|
    w.times.map { |x|
      n[y * w + x] == 1 ? ?# : ' '
    }.join
  }.join("\n")
end

*presents, trees = ARGF.readlines("\n\n", chomp: true)
presents.map!(&method(:present)).freeze

trees = trees.each_line.map { |line|
  sz, counts = line.split(': ', 2)
  [sz.split(?x, 2).map(&method(:Integer)).freeze, counts.split.map(&method(:Integer)).freeze].freeze
}.freeze

possible = trees.select { |(w, h), count|
  count.zip(presents).sum { |a, b| a * b[0].to_s(2).count(?1) } <= w * h
}
definitely_possible, maybe_possible = possible.partition { |(w, h), count|
  (w / 3) * (h / 3) >= count.sum
}
puts definitely_possible.size
puts possible.size
puts definitely_possible.size + maybe_possible.count { |(w, h), count|
  free = (1 << (w * h)) - 1
  presents_expanded = presents.map { |variants| variants.map { expand(it, w) }.freeze }.freeze
  count_expanded = count.each_with_index.flat_map { |k, n| Array.new(k, n) }.freeze
  fit?(presents_expanded, count_expanded, w, h, free, 0)
} if slow
