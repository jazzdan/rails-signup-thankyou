class CallGraphStorage
  def initialize
    @datalog_program = ""
    @count = 0
  end

  def add_parent(subject, target)
    @datalog_program += "parent(\"#{subject}\", \"#{target}\").\n"
    @count = @count + 1
  end

  def add_child(subject, target, path)
    @datalog_program += "child(\"#{subject}\", \"#{target}\", \"#{path}\").\n"
    @count = @count + 1
  end

  def output_datalog
    File.open('run_facts.pl', 'w') { |file| file.write(@datalog_program) }
  end
end

class GraphManager
  def initialize(options)
    @stack   = ["start"]
    @edges   = []
    @options = options

    @cgs = CallGraphStorage.new
  end

  def add_edges(event)
    node = get_node_name(event)
    #       parent,      child
    edge = [@stack.last, node]
    @cgs.add_parent(node, @stack.last)
    @cgs.add_child(@stack.last, node, event.path)
    @stack << node


    return if @edges.include?(edge)

    @edges << edge
  end

  def get_node_name(event)
    if @options[:show_path]
      "#{event.defined_class}##{event.method_id}\n#{event.path}".freeze
    else
      "#{event.defined_class}##{event.method_id}".freeze
    end
  end

  def output_datalog
    @cgs.output_datalog
  end

  def pop
    @stack.pop
  end
end

module VisualCallGraph
  extend self

  def trace(options = {})
    unless block_given?
      puts "Block required"
      return
    end

    graph = GraphManager.new(options)

    trace =
    TracePoint.new(:call, :return) do |event|
      case event.event
      when :return then graph.pop
      when :call   then graph.add_edges(event)
      end
    end

    trace.enable
    yield
    trace.disable

    graph.output_datalog
  end
end
