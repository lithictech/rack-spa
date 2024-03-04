# frozen_string_literal: true

lib = File.expand_path("lib", __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require "rack/lambda_app"
require "rack/spa_app"
require "rack/dynamic_config_writer"

class Api
  def call(*)
    b = '{"hello":"world"}'
    [200, {"content-type" => "application/json"}, [b]]
  end
end
map "/api" do
  run Api.new
end

ui = Rack::Builder.new do
  dw = Rack::DynamicConfigWriter.new(
    "jsapp/index.html",
  )
  env = {
    "VITE_API_HOST" => "/api",
    "VITE_RELEASE" => "ui@1.0.0",
    "NODE_ENV" => "production",
  }
  index_bytes = dw.as_string(env)
  Rack::SpaApp.run_spa_app(self, "jsapp", enforce_ssl: false, index_bytes:)
end

map "/ui" do
  run ui.to_app
end
