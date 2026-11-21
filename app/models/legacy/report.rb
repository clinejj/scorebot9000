module Legacy
  # Reconciliation report for a legacy import: source vs imported counts,
  # anomalies (orphans, invalid phones, duplicates, merges) and per-event
  # result diffs. Persisted as JSON on LegacyImport.
  class Report
    attr_reader :data

    def initialize(data = {})
      @data = data.deep_dup.presence || { "counts" => {}, "warnings" => {}, "events" => {} }
    end

    def count(kind, source: nil, imported: nil)
      entry = (data["counts"][kind.to_s] ||= {})
      entry["source"] = source unless source.nil?
      entry["imported"] = imported unless imported.nil?
    end

    def warn(category, message)
      list = (data["warnings"][category.to_s] ||= [])
      list << message unless list.include?(message)
    end

    def event(legacy_id, **details)
      (data["events"][legacy_id.to_s] ||= {}).merge!(details.deep_stringify_keys)
    end

    def warnings(category)
      data["warnings"].fetch(category.to_s, [])
    end

    def to_h = data
  end
end
