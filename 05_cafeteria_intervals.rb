# Assumes without checking that input intervals are sorted by start time.
def merge(intervals, merge_adjacent: true)
  prev_min = intervals[0].begin
  prev_max = intervals[0].end
  (intervals.each_with_object([]) { |r, merged|
    if r.begin > prev_max + (merge_adjacent ? 1 : 0)
      merged << (prev_min..prev_max)
      prev_min = r.begin
      prev_max = r.end
    else
      prev_max = [prev_max, r.end].max
    end
  } << (prev_min..prev_max)).freeze
end

ranges = merge(ARGF.readline("\n\n", chomp: true).each_line.map { |line|
  Range.new(*line.split(?-, 2).map(&method(:Integer)))
}.sort_by(&:begin))

ingredients = ARGF.map(&method(:Integer)).freeze

puts ingredients.count { |ingr| ranges.any? { |rng| rng.cover?(ingr) }}
puts ranges.sum(&:size)
