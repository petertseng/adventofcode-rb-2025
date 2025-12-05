def largest_number(n, digits_after)
  return n.max if digits_after == 0

  max, i = n[...-digits_after].each_with_index.max_by(&:first)
  max * 10 ** digits_after + largest_number(n[(i + 1)..], digits_after - 1)
end

bank = ARGF.map { |line| line.chomp.chars.map(&method(:Integer)).freeze }.freeze

[1, 11].each { |n|
  puts bank.sum { largest_number(it, n) }
}
