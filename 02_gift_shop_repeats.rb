# split a range into several, each with equal digits for begin and end
# ranges_equal_digits(5, 15) == [5..9, 10..15]
def ranges_equal_digits(l, r)
  lsz = l.to_s.size
  rsz = r.to_s.size
  (lsz..rsz).map { |n|
    (n == lsz ? l : 10 ** (n - 1))..(n == rsz ? r : 10 ** n - 1)
  }
end

ranges = ARGF.read.split(?,).flat_map { |range|
  ranges_equal_digits(*range.split(?-, 2).map(&method(:Integer)))
}.freeze

# the sum of the multiples of N within the range
def sum_multiples(n, range)
  l = range.begin / n + (range.begin % n == 0 ? 0 : 1)
  r = range.end / n
  (l..r).sum * n
end

def repeat2(range)
  sz = range.begin.to_s.size
  return 0 if sz.odd?
  sum_multiples(10 ** (sz / 2) + 1, range)
end

def repeat_any(range)
  case sz = range.begin.to_s.size
  when 1; 0
  when 2; sum_multiples(11, range)
  when 3; sum_multiples(111, range)
  when 4; sum_multiples(101, range)
  when 5; sum_multiples(11111, range)
  when 6; sum_multiples(1001, range) + sum_multiples(10101, range) - sum_multiples(111111, range)
  when 7; sum_multiples(1111111, range)
  when 8; sum_multiples(10001, range)
  when 9; sum_multiples(1001001, range)
  when 10; sum_multiples(100001, range) + sum_multiples(101010101, range) - sum_multiples(1111111111, range)
  else raise "TODO: handle size #{sz}"
  end
end

puts ranges.sum(&method(:repeat2))
puts ranges.sum(&method(:repeat_any))
