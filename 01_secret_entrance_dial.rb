DIR = {?L => -1, ?R => 1}.freeze

pos = 50

poses = ARGF.map { |line|
  pos = (pos % 100) + Integer(line[1..]) * DIR.fetch(line[0])
}.unshift(50).freeze

puts poses.count { it % 100 == 0 }

puts poses.each_cons(2).sum { |prev, pos|
  # Note that 0 <= prev < 100, due to % 100 above.
  if pos <= 0
    # new position negative:
    # how many times we pass 0 if we went from a nonzero number to:
    #  -99: 1
    # -100: 2
    # -101: 2
    # so we should divide by -100.
    # Rely on the fact that in this language, division truncates toward zero.
    # Also note that starting from 0 means we pass 0 one fewer time.
    pos / -100 + (prev % 100 == 0 ? 0 : 1)
  else
    # new position positive:
    # hundreds digit tells how many times it passed 0
    pos / 100
  end
}
