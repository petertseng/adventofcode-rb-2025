*num_lines, ops = ARGF.map(&:freeze).freeze
ops = ops.split.map(&:to_sym).freeze

math = ->numses { numses.zip(ops).sum { |nums, op| nums.map(&method(:Integer)).reduce(&op) } }

puts math[num_lines.map(&:split).transpose]
puts math[num_lines.map(&:chars).transpose.slice_after { |x| x.all?(' ') }.map { it[..-2].map(&:join) }]
