DIR = {?L => -1, ?R => 1}.freeze

pos = 50

poses = ARGF.map { |line|
  pos = (pos % 100) + Integer(line[1..]) * DIR.fetch(line[0])
}.unshift(50).freeze

puts poses.count { it % 100 == 0 }

puts poses.each_cons(2).sum { |prev, pos|
  pos <= 0 ? pos / -100 + (prev % 100 == 0 ? 0 : 1) : pos / 100
}
