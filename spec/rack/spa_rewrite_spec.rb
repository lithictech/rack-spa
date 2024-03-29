# frozen_string_literal: true

require "timecop"

require "rack/spa_rewrite"

RSpec.describe Rack::SpaRewrite do
  around(:each) do |ex|
    Timecop.freeze("2022-10-30T00:00:00Z") do
      ex.run
    end
  end

  let(:app) { ->(_env) { [200, {}, "success"] } }
  let(:index_path) { Pathname(__FILE__).dirname.parent + "data" + "spa/index.html" }
  let(:index_bytes) { File.read(index_path.to_s) }

  let(:modtimehttp) { "Sun, 30 Oct 2022 00:00:00 GMT" }

  it "handles GETs" do
    mw = described_class.new(app, index_bytes:, html_only: false)
    expect(mw.call(Rack::MockRequest.env_for("/w", method: :get))).to eq(
      [
        200,
        {"content-length" => "13", "content-type" => "text/html", "last-modified" => "Sun, 30 Oct 2022 00:00:00 GMT"},
        ["<html></html>"],
      ],
    )
  end

  it "handles HEADs" do
    mw = described_class.new(app, index_bytes:, html_only: false)
    expect(mw.call(Rack::MockRequest.env_for("/w", method: :head))).to match_array(
      [
        200,
        {"content-length" => "13", "content-type" => "text/html", "last-modified" => "Sun, 30 Oct 2022 00:00:00 GMT"},
        be_empty,
      ],
    )
  end

  it "handles OPTIONs" do
    mw = described_class.new(app, index_bytes:, html_only: false)
    expect(mw.call(Rack::MockRequest.env_for("/w", method: :options))).to eq(
      [200, {"Allow" => "GET, HEAD, OPTIONS", "content-length" => "0"}, []],
    )
  end

  it "returns 304 if if-none-match check succeeds" do
    mw = described_class.new(app, index_bytes:, html_only: false)
    env = Rack::MockRequest.env_for("/w", method: :get, "HTTP_IF_MODIFIED_SINCE" => modtimehttp)
    expect(mw.call(env)).to eq([304, {}, []])
  end

  it "returns 200 if if-none-matches check fails" do
    mw = described_class.new(app, index_bytes:, html_only: false)
    env = Rack::MockRequest.env_for("/w", method: :get, "HTTP_IF_MODIFIED_SINCE" => (Time.now + 1).httpdate)
    expect(mw.call(env)).to eq(
      [
        200,
        {"content-length" => "13", "content-type" => "text/html", "last-modified" => "Sun, 30 Oct 2022 00:00:00 GMT"},
        ["<html></html>"],
      ],
    )
  end

  describe "with html_only true" do
    let(:mw) { described_class.new(app, index_bytes:, html_only: true) }

    it "calls the underlying app if the request does not end with html" do
      expect(mw.call(Rack::MockRequest.env_for("/w", method: :get))).to eq([200, {}, "success"])
    end

    it "returns the file if the request ends with html" do
      expect(mw.call(Rack::MockRequest.env_for("/w.html", method: :get))).to eq(
        [
          200,
          {"content-length" => "13", "content-type" => "text/html", "last-modified" => "Sun, 30 Oct 2022 00:00:00 GMT"},
          ["<html></html>"],
        ],
      )
    end
  end

  describe "with html_only false" do
    let(:mw) { described_class.new(app, index_bytes:, html_only: false) }

    it "returns the file if the request does not end with html" do
      expect(mw.call(Rack::MockRequest.env_for("/w", method: :get))).to eq(
        [
          200,
          {"content-length" => "13", "content-type" => "text/html", "last-modified" => "Sun, 30 Oct 2022 00:00:00 GMT"},
          ["<html></html>"],
        ],
      )
    end

    it "returns the file if the request ends with html" do
      expect(mw.call(Rack::MockRequest.env_for("/w.html", method: :get))).to eq(
        [
          200,
          {"content-length" => "13", "content-type" => "text/html", "last-modified" => "Sun, 30 Oct 2022 00:00:00 GMT"},
          ["<html></html>"],
        ],
      )
    end
  end
end
