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

outer_nils.each { |pos| outside[pos] = true }

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

max = 0
max_inside = 0
points.combination(2) { |(x1, y1), (x2, y2)|
  area = ((x1 - x2).abs + 1) * ((y1 - y2).abs + 1)
  max = [max, area].max
  next if area <= max_inside

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

  max_inside = area
}
puts max
puts max_inside
