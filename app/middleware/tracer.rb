require_relative '../../lib/visual_call_graph.rb'

class Tracer
  def initialize app
    @app = app
  end

  def call env
    VisualCallGraph.trace {
      @status, @headers, @response = @app.call(env)
    }

    [@status, @headers, @response]
  end
end
