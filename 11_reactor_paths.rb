dsts = ARGF.to_h { |line|
  src, dsts = line.split(': ', 2)
  [src.to_sym, dsts.split.map(&:to_sym).freeze]
}.freeze

DAC = 1
FFT = 2

cache = [
  {out: 1},
  {out: 0},
  {out: 0},
  {out: 0},
].freeze

paths_to_out = ->(node, visited) {
  cache[visited][node] ||= begin
    case node
    when :dac
      raise "asked for dac without visiting it #{visited}" if visited & DAC == 0
      dsts.fetch(:dac).sum { paths_to_out[it, visited & ~DAC] + paths_to_out[it, visited] }
    when :fft
      raise "asked for fft without visiting it #{visited}" if visited & FFT == 0
      dsts.fetch(:fft).sum { paths_to_out[it, visited & ~FFT] + paths_to_out[it, visited] }
    else
      dsts.fetch(node).sum { paths_to_out[it, visited] }
    end
  end
}

puts dsts[:you] ? cache.each_index.sum { paths_to_out[:you, it] } : 0
puts dsts[:svr] ? paths_to_out[:svr, DAC | FFT] : 0
