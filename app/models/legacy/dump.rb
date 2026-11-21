module Legacy
  # A parsed legacy Datastore dump: one JSON object per line,
  #   {"kind": "player", "key": "...", "properties": {"playerID": "+1909...", ...}}
  # as written by script/legacy/dump_datastore.rb.
  class Dump
    KINDS = %w[setting event game player score name text].freeze

    def self.parse(content)
      records = Hash.new { |hash, kind| hash[kind] = [] }
      content.to_s.each_line.with_index(1) do |line, number|
        next if line.strip.empty?

        row = JSON.parse(line)
        records[row.fetch("kind")] << row.fetch("properties").merge("__key" => row["key"], "__line" => number)
      rescue JSON::ParserError, KeyError => error
        raise ArgumentError, "Line #{number} of the dump isn't valid: #{error.message}"
      end
      new(records)
    end

    def initialize(records)
      @records = records
    end

    def [](kind)
      @records.fetch(kind.to_s, [])
    end

    def counts
      KINDS.index_with { |kind| self[kind].size }
    end
  end
end
