#!/usr/bin/env ruby
# Dumps the legacy Scorebot 9000 Datastore (GCP project "clinelympics") to a
# JSONL file for the importer at /admin/legacy_imports.
#
# The output contains phone numbers: keep it out of git (tmp/ is ignored) and
# only upload it to the admin import page.
#
# Usage (on a machine with owner access to the project):
#   gcloud auth application-default login
#   ruby script/legacy/dump_datastore.rb --project clinelympics --out tmp/legacy/legacy_dump.jsonl
require "bundler/inline"

gemfile do
  source "https://rubygems.org"
  gem "google-cloud-datastore", "~> 2.0"
end

require "fileutils"
require "json"
require "optparse"
require "time"

KINDS = %w[setting event game player score name text].freeze

options = { project: "clinelympics", out: "tmp/legacy/legacy_dump.jsonl" }
OptionParser.new do |parser|
  parser.on("--project ID", "GCP project ID (default: clinelympics)") { |value| options[:project] = value }
  parser.on("--out PATH", "Output file (default: tmp/legacy/legacy_dump.jsonl)") { |value| options[:out] = value }
end.parse!

def plain(value)
  case value
  when Time, DateTime then value.to_time.utc.iso8601(3)
  when Google::Cloud::Datastore::Key then value.path.map { |kind, id| "#{kind}:#{id}" }.join("/")
  when Array then value.map { |item| plain(item) }
  else value
  end
end

datastore = Google::Cloud::Datastore.new(project_id: options[:project])
FileUtils.mkdir_p(File.dirname(options[:out]))

File.open(options[:out], "w") do |file|
  KINDS.each do |kind|
    count = 0
    datastore.run(datastore.query(kind)).all do |entity|
      properties = entity.properties.to_h.transform_values { |value| plain(value) }
      key = entity.key.path.map { |path_kind, id| "#{path_kind}:#{id}" }.join("/")
      file.puts JSON.generate("kind" => kind, "key" => key, "properties" => properties)
      count += 1
    end
    warn format("%-8s %6d", kind, count)
  end
end

warn "Wrote #{options[:out]}"
