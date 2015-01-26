
QCMethodCall = Struct.new(:class_name, :method_name, :type) do
  attr_reader :events

  def initialize(*args)
    super
    @events = []
  end

  def immediately_equal?(other)
    return other.is_a?(QCMethodCall) && other.class_name == self.class_name && other.method_name == self.method_name && other.type == self.type
  end

  def shallow_equal?(other)
    return immediately_equal?(other) && other.events.length == self.events.length && events.zip(other.events).all? { |s, o| s.immediately_equal?(o) }
  end

  def check_equality(other, indent=0)
    puts "#{' ' * indent}#{class_name}##{method_name} (#{type})"
    if shallow_equal?(other)
      events.zip(other.events).select { |s, o| s.is_a? QCMethodCall }.each do |(s, o)|
        s.check_equality(o, indent + 1)
      end
    else
      puts "#{' '* (indent + 1)}CONTENTS DIFFER"
    end
  end
end

QCEvent = Struct.new(:file, :line) do
  def immediately_equal?(other)
    return other.is_a?(QCEvent) && other.file == self.file && other.line == self.line
  end
end

def trace_and_track(&block)
  stack2 = [QCMethodCall.new('toplevel', :toplevel, :toplevel)]
  stats = [0, 0]
  begin
    trace_point = TracePoint.new(:line, :call, :return, :c_call, :c_return, :b_call, :b_return) do |tp|
      begin
        if tp.event == :c_call || tp.event == :call || tp.event == :b_call
          stats[0] = stats[0] + 1
          call = QCMethodCall.new(tp.defined_class.inspect, tp.method_id, tp.event == :b_call ? :block : :method)
          stack2[-1].events.push(call) if stack2[-1]
          stack2.push(call)
        elsif tp.event == :c_return || tp.event == :return || tp.event == :b_return
          stats[1] = stats[1] + 1
          p = stack2[-1]
          real = QCMethodCall.new(tp.defined_class.inspect, tp.method_id, tp.event == :b_return ? :block : :method)
          unless real.immediately_equal?(p)
            puts "INVALID POP: Expected #{p} but got #{real}"
          else
            stack2.pop
          end
        elsif tp.event == :line
          stack2[-1].events.push(QCEvent.new(tp.path, tp.lineno)) if stack2[-1]
        end
      rescue => e
        puts "Exception: #{e}"
      end
    end
    trace_point.enable &block
  ensure
    trace_point.disable
  end
  puts "STATS: #{stats}"
  stack2[0]
end

def trace2(&block)
  r1 = trace_and_track(&block)
  r2 = trace_and_track(&block)
  if r1 != r2
    raise 'Fragile test'
  end
  r1
end
