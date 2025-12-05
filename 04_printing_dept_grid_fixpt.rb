TOWEL = {
  ?@ => true,
  ?. => false,
  ?\n => false,
}.freeze

width = nil

towel = ARGF.flat_map { |line|
  # intentionally no chomp, using \n as an extra space to avoid wrapping
  width ||= line.size
  raise "inconsistent width #{line.size} != #{width}" if line.size != width

  line.each_char.map { TOWEL.fetch(it) }
}
# intentionally no freeze, will mutate

dposes = [-width - 1, -width, -width + 1, -1, 1, width - 1, width, width + 1].freeze
active = towel.each_with_index.filter_map { |c, i| i if c }.freeze
orig_sz = active.size

1.step { |t|
  remove = active.select { |pos|
    dposes.count { |dpos| pos + dpos >= 0 && towel[pos + dpos] } < 4
  }.freeze
  puts remove.size if t == 1
  break puts orig_sz - towel.count(true) if remove.empty?
  remove.each { towel[it] = false }
  active = remove.flat_map { |rem|
    dposes.filter_map { |dpos| npos = rem + dpos; npos if npos >= 0 && towel[npos] }
  }.uniq.freeze
}
