# frozen_string_literal: true

require "rack"
require "nokogiri"
require "json"

# Allow dynamic configuration of a SPA.
# When the backend app starts up, it should run #emplace.
# This will 1) copy the index.html to a 'backup' location
# if it does not exist, 2) replace a placeholder string
# in the index.html with the given keys and values
# (use .pick_env_vars to pull everything like 'REACT_APP_'),
# and write it out to index.html.
#
# IMPORTANT: This sort of dynamic config writing is not normal
# for SPAs so needs some further explanation.
# The build process should be exactly the same;
# for example, you'd still run `npm run build`,
# and generate a totally normal build output.
# It's the *backend* running that modifies index.html
# (and creates index.html.original) *at backend startup*,
# not at build time.
module Rack
  class DynamicConfigWriter
    GLOBAL_ASSIGN = "window.rackDynamicConfig"
    BACKUP_SUFFIX = ".original"

    def initialize(
      index_html_path,
      global_assign: GLOBAL_ASSIGN,
      backup_suffix: BACKUP_SUFFIX
    )
      @index_html_path = index_html_path.to_s
      @global_assign = global_assign
      @index_html_backup = @index_html_path + backup_suffix
    end

    # Copy +index_html_path+ to index.html.original (see +BACKUP_SUFFIX+),
    # and add the dynamic config to +index_html_path+.
    # Use +as_string+ to avoid file writes.
    def emplace(keys_and_values)
      self.ensure_unmodified_html_backup
      ::File.open(@index_html_backup) do |f|
        new_html = self.serialize(f, keys_and_values)
        ::File.write(@index_html_path, new_html)
      end
    end

    protected def ensure_unmodified_html_backup
      return if ::File.exist?(@index_html_backup)
      ::FileUtils.move(@index_html_path, @index_html_backup)
    end

    # Return the new index.html with dynamic config as a string.
    def as_string(keys_and_values)
      ::File.open(@index_html_path) do |f|
        return self.serialize(f, keys_and_values)
      end
    end

    protected def serialize(f, keys_and_values)
      json = JSON.generate(keys_and_values)
      script = "#{@global_assign}=#{json}"
      doc = Nokogiri::HTML5(f)
      doc.at("head").prepend_child("<script>#{script}</script>")
      return doc.serialize
    end

    def self.pick_env(regex_or_prefix)
      return ENV.to_a.select { |(k, _v)| k.start_with?(regex_or_prefix) }.to_h if regex_or_prefix.is_a?(String)
      return ENV.to_a.select { |(k, _v)| regex_or_prefix.match?(k) }.to_h
    end
  end
end
