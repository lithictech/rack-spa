# frozen_string_literal: true

require "rack/immutable"
require "rack/lambda_app"
require "rack/simple_redirect"
require "rack/spa_rewrite"

module Rack
  class SpaApp
    # Return Rack middleware dependencies for the SPA app.
    # @param build_folder [String,Pathname] Path to the build folder.
    # @param immutable [true,false] True to use +Rack::Immutable+ middleware,
    #   so that files that look fingerprinted (<name>.<git sha>.ext) get immutable cache headers.
    # @param enforce_ssl [true,false] True to use +Rack::SsslEnforcer+. Requires `rack-ssl-enforcer` gem.
    # @param service_worker_allowed [String,nil] Scope of the server worker for the Service-Worker-Allowed header.
    # @param index_bytes [String,nil] Bytes of the app's index.html file. If not passed,
    #   use the contents of `<build_folder>/index.html`.
    def self.dependencies(
      build_folder,
      immutable: true,
      enforce_ssl: true,
      service_worker_allowed: nil,
      index_bytes: nil
    )
      index_bytes ||= File.read("#{build_folder}/index.html")
      result = []
      result << [Rack::SslEnforcer, {redirect_html: false}] if enforce_ssl
      result << [Rack::ConditionalGet, {}]
      result << [Rack::ETag, {}]
      result << [Rack::Immutable, {match: immutable.is_a?(TrueClass) ? nil : immutable}] if immutable
      result << [Rack::SpaRewrite, {index_bytes:, html_only: true}]
      result << [Rack::ServiceWorkerAllowed, {scope: service_worker_allowed}] if service_worker_allowed
      result << [Rack::Static, {urls: [""], root: build_folder.to_s, cascade: true}]
      result << [Rack::SpaRewrite, {index_bytes:, html_only: false}]
      return result
    end

    def self.install(builder, dependencies)
      dependencies.each { |cls, opts| builder.use(cls, **opts) }
    end

    def self.run(builder)
      builder.run Rack::LambdaApp.new(->(_) { raise "Should not see SpaApp fallback" })
    end

    def self.run_spa_app(builder, build_folder, enforce_ssl: true, immutable: true, index_bytes: nil, **kw)
      deps = self.dependencies(build_folder, enforce_ssl:, immutable:, index_bytes:, **kw)
      self.install(builder, deps)
      self.run(builder)
    end
  end
end
