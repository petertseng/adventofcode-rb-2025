start, width = ARGF.readline.then {
  raise "line 0 #{it} should only have S" unless it.match?(/^\.*S\.*$/)
  [it.index(?S), it.size]
}

splits = 0

timelines = ARGF.reduce(Array.new(width) { it == start ? 1 : 0 }.freeze) { |beam, row|
  x = -1
  new_beam = beam.dup
  while (x = row.index(?^, x + 1))
    next unless (n = beam[x]) > 0
    splits += 1
    new_beam[x] -= n
    new_beam[x - 1] += n
    new_beam[x + 1] += n
  end
  new_beam.freeze
}.sum

puts splits
puts timelines
