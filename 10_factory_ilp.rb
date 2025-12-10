# Opt checks whether Glpk is defined to determine whether that solver is available
require 'glpk'
require 'opt-rb'

def between(l, r, s)
  raise "#{s} doesn't start with #{l}" unless s.start_with?(l)
  raise "#{s} doesn't end with #{r}" unless s.end_with?(r)
  s[1..-2]
end

BIT = {
  ?. => 0,
  ?# => 1,
}.freeze

circuits = ARGF.map { |line|
  lights, *buttons, jolts = line.split
  lights = between(?[, ?], lights).each_char.with_index.sum { |c, i| BIT.fetch(c) << i }
  buttons.map! { between(?(, ?), it).split(?,).map(&method(:Integer)).freeze }.freeze
  jolts = between(?{, ?}, jolts).split(?,).map(&method(:Integer)).freeze
  [lights, buttons, jolts].freeze
}.freeze

def steps(lights, buttons)
  # hit each button 0 or 1 times, since hitting twice resets to 0
  (1..buttons.size).find { |n|
    buttons.combination(n).any? { |c|
      c.reduce(0, :^) == lights
    }
  }
end

puts circuits.sum { |lights, buttons, _|
  steps(lights, buttons.map { |wires| wires.sum { 1 << it }}.freeze)
}

puts circuits.sum { |_, buttons, jolts|
  optbuts = buttons.each_index.map { |i| Opt::Integer.new(0.., "button#{i}") }.freeze
  prob = Opt::Problem.new
  jolts.each_with_index { |jolt, i|
    relevant_buttons = optbuts.zip(buttons).filter_map { |optbut, but| optbut if but.include?(i) }
    prob.add(relevant_buttons.sum == jolt)
  }
  prob.minimize(optbuts.sum)
  prob.solve
  optbuts.sum(&:value)
}
