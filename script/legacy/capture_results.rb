#!/usr/bin/env ruby
# Captures the results pages from the live legacy site, before it's retired,
# so the new app can show exactly what was announced (plan section 11.3).
#
# Writes db/legacy_results/event_N.json (safe to commit: the pages show only
# aliases and team names) and raw HTML copies to tmp/legacy/html/.
#
# Usage:
#   ruby script/legacy/capture_results.rb                    # events 1-10 from https://clinelympics.com
#   ruby script/legacy/capture_results.rb --events 1-3 --base https://clinelympics.com
require "bundler/inline"

gemfile do
  source "https://rubygems.org"
  gem "nokogiri"
end

require "fileutils"
require "json"
require "net/http"
require "optparse"
require "time"

options = { base: "https://clinelympics.com", events: (1..10), out: "db/legacy_results", html: "tmp/legacy/html" }
OptionParser.new do |parser|
  parser.on("--base URL") { |value| options[:base] = value.chomp("/") }
  parser.on("--events RANGE", "e.g. 1-10 or 4") do |value|
    first, last = value.split("-").map(&:to_i)
    options[:events] = (first..(last || first))
  end
  parser.on("--out DIR") { |value| options[:out] = value }
end.parse!

def squish(text) = text.to_s.gsub(/[[:space:]]+/, " ").strip

def fetch(url)
  response = Net::HTTP.get_response(URI(url))
  raise "#{url} returned #{response.code}" unless response.is_a?(Net::HTTPSuccess)

  response.body.force_encoding("UTF-8")
end

FileUtils.mkdir_p(options[:out])
FileUtils.mkdir_p(options[:html])

options[:events].each do |event_id|
  pages = %w[summary medals scores].to_h do |page|
    url = "#{options[:base]}/#{page}.jsp?e=#{event_id}"
    html = fetch(url)
    File.write(File.join(options[:html], "#{page}_#{event_id}.html"), html)
    [ page, html ]
  end

  doc = Nokogiri::HTML(pages["summary"])
  tables = {}
  doc.css("h3").each do |heading|
    key = squish(heading.text).downcase.gsub(/[^a-z]+/, "_").gsub(/\A_|_\z/, "")
    table = heading.xpath("following::table[1]").first or next
    tables[key] = {
      "headers" => table.css("thead th").map { |cell| squish(cell.text) },
      "rows" => table.css("tbody tr").map { |row| row.css("td").map { |cell| squish(cell.text) } }
    }
  end

  count_table = tables["team_medal_count"] || tables["player_medal_count"]
  medal_names = count_table ? count_table["headers"][1..-2].reject { |header| header == "Team" } : []
  data = {
    "legacy_event_id" => event_id,
    "title" => squish(doc.at("h2")&.text),
    "source_url" => "#{options[:base]}/summary.jsp?e=#{event_id}",
    "captured_at" => Time.now.utc.iso8601,
    "medal_names" => medal_names,
    "tables" => tables
  }
  path = File.join(options[:out], "event_#{event_id}.json")
  File.write(path, JSON.pretty_generate(data) + "\n")
  warn "event #{event_id}: #{data["title"]} (#{tables.keys.join(", ")}) -> #{path}"
end
