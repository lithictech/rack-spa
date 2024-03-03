# frozen_string_literal: true

require "rack"

module Rack
  class Csp
    def initialize(app, policy:)
      @app = app
      @policy = policy
    end

    def call(env)
      status, headers, body = @app.call(env)
      headers["Content-Security-Policy"] = @policy
      [status, headers, body]
    end
  end
end
