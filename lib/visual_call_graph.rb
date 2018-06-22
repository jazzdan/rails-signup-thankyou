require 'graphviz'

class GraphManager
  def initialize(options)
    @stack   = ["start"]
    @edges   = []
    @options = options

    @g = GraphViz.new(:G, :type => :digraph)

    @g.add_node("start")
  end

  def add_edges(event)
    node = get_node_name(event)
    edge = [@stack.last, node]

    @stack << node

    return if @edges.include?(edge)

    @edges << edge
    @g.add_edge(*@edges.last)
  end

  def get_node_name(event)
    if @options[:show_path]
      "#{event.defined_class}##{event.method_id}\n#{event.path}".freeze
    else
      "#{event.defined_class}##{event.method_id}".freeze
    end
  end

  def output(*args)
    @g.output(*args)
  end

  def node_count
    @g.node_count
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

    graph.output(png: "#{Dir.pwd}/call_graph.png")

    puts "Call graph created with a total of #{node_count(graph)}."
  end

  def node_count(graph)
    "#{graph.node_count} #{(graph.node_count > 1 ? 'nodes' : 'node')}"
  end
end
