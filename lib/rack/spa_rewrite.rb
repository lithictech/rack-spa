# frozen_string_literal: true

require "rack"

module Rack
  # Intercept HTTP requests and serve index.html.
  # This middleware caches the index_html file (or the bytes can be passed in).
  # If the file contents change, new content is NOT served.
  class SpaRewrite
    ALLOWED_VERBS = ["GET", "HEAD", "OPTIONS"].freeze
    ALLOW_HEADER = ALLOWED_VERBS.join(", ")

    # @param app The Rack app.
    # @param index_bytes [String] The index.html contents to serve.
    # @param html_only [true,false] True to only intercept html requests,
    #   false to intercept all requests. Usually you want to setup SpaRewrite
    #   first using html:false, then html:true as the final Rack app/middleware.
    def initialize(app, index_bytes:, html_only:)
      @app = app
      @index_bytes = index_bytes
      @html_only = html_only
      @head = Rack::Head.new(->(env) { get env })
      @started_at = Time.now.httpdate
    end

    def call(env)
      # HEAD requests drop the response body, including 4xx error messages.
      @head.call env
    end

    def get(env)
      request = Rack::Request.new env
      return @app.call(env) if @html_only && !request.path_info.end_with?(".html")
      return [405, {"Allow" => ALLOW_HEADER}, ["Method Not Allowed"]] unless
        ALLOWED_VERBS.include?(request.request_method)

      path_info = Rack::Utils.unescape_path(request.path_info)
      return [400, {}, ["Bad Request"]] unless Rack::Utils.valid_path?(path_info)

      return [200, {"Allow" => ALLOW_HEADER, Rack::CONTENT_LENGTH => "0"}, []] if
        request.options?

      return [304, {}, []] if request.get_header("HTTP_IF_MODIFIED_SINCE") == @started_at

      headers = {
        "content-length" => @index_bytes.bytesize.to_s,
        "content-type" => "text/html",
        "last-modified" => @started_at,
      }
      return [200, headers, [@index_bytes]]
    end
  end
end
