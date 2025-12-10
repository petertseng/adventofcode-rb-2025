require 'benchmark'

bench_candidates = []

def opt(circuits, solver)
  circuits.sum { |_, buttons, jolts|
    optbuts = buttons.each_index.map { |i| Opt::Integer.new(0.., "button#{i}") }.freeze
    prob = Opt::Problem.new
    jolts.each_with_index { |jolt, i|
      relevant_buttons = optbuts.zip(buttons).filter_map { |optbut, but| optbut if but.include?(i) }
      prob.add(relevant_buttons.sum == jolt)
    }
    prob.minimize(optbuts.sum)
    prob.solve(solver: solver)
    optbuts.sum(&:value)
  }
end

begin
  require 'glpk'
  require 'opt-rb'
  bench_candidates << def glpk(circuits)
    opt(circuits, :glpk)
  end
rescue LoadError
  puts 'skip glpk, no gem'
end

begin
  require 'cbc'
  require 'opt-rb'
  bench_candidates << def cbc(circuits)
    opt(circuits, :cbc)
  end
rescue LoadError
  puts 'skip cbc, no gem'
end

begin
  require 'z3'
  bench_candidates << def z3(circuits)
    circuits.sum { |_, buttons, jolts|
      opter = Z3::Optimize.new
      z3buts = buttons.each_index.map { |i| Z3.Int("button#{i}") }.freeze
      z3buts.each { opter.assert(it >= 0) }
      jolts.each_with_index { |jolt, i|
        relevant_buttons = z3buts.zip(buttons).filter_map { |z3but, but| z3but if but.include?(i) }
        opter.assert(jolt == relevant_buttons.sum)
      }
      opter.minimize(z3buts.sum)
      raise "can't make #{jolts} with #{buttons}" if opter.unsatisfiable?
      z3buts.sum { opter.model[it] }.to_i
    }
  end
rescue LoadError
  puts 'skip z3, no gem'
end

def between(l, r, s)
  raise "#{s} doesn't start with #{l}" unless s.start_with?(l)
  raise "#{s} doesn't end with #{r}" unless s.end_with?(r)
  s[1..-2]
end

circuits = ARGF.map { |line|
  _, *buttons, jolts = line.split
  lights = nil # don't bother parsing in benchmark
  buttons.map! { between(?(, ?), it).split(?,).map(&method(:Integer)).freeze }.freeze
  jolts = between(?{, ?}, jolts).split(?,).map(&method(:Integer)).freeze
  [lights, buttons, jolts].freeze
}.freeze

results = {}

Benchmark.bmbm { |bm|
  bench_candidates.each { |f|
    bm.report(f) { 3.times { results[f] = send(f, circuits) } }
  }
}

# Obviously the benchmark would be useless if they got different answers.
if results.values.uniq.size != 1
  results.each { |k, v| puts "#{k} #{v}" }
  raise 'differing answers'
end
