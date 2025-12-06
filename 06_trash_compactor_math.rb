*operands_raw, ops = ARGF.map(&:freeze).freeze
ops = ops.split.map(&:to_sym).freeze

math = ->operandses { operandses.zip(ops).sum { |operands, op| operands.map(&method(:Integer)).reduce(&op) } }

puts math[operands_raw.map(&:split).transpose]
puts math[operands_raw.map(&:chars).transpose.slice_after { |x| x.all?(' ') }.map { it[..-2].map(&:join) }]
