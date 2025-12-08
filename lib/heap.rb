class Heap
  attr_reader :size

  def initialize(elts)
    @elts = elts.dup
    @size = elts.size
    (@size / 2 - 1).downto(0) { |i| down(i) }
  end

  def first
    @elts[0]
  end

  def pop
    return nil if @size == 0
    @size -= 1
    return @elts.pop if @elts.size == 1
    @elts[0].tap {
      @elts[0] = @elts[@size]
      down(0)
    }
  end

  private

  def down(i)
    l = 2 * i + 1
    r = 2 * i + 2
    smallest = i
    smallest = l if l < @size && @elts[l][0] < @elts[smallest][0]
    smallest = r if r < @size && @elts[r][0] < @elts[smallest][0]
    return if smallest == i
    @elts[i], @elts[smallest] = @elts[smallest], @elts[i]
    down(smallest)
  end
end
