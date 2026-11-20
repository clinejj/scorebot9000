# Converts the organizer console's scoring fields to and from the stored
# Scoring::Config hash (a preset plus overrides).
module ScoringForm
  module_function

  def to_config(fields)
    fields = (fields || {}).to_h.stringify_keys
    config = { "preset" => fields["preset"].presence || Scoring::Config::DEFAULT_PRESET }
    config["ranking"] = fields["ranking"] if fields["ranking"].present?
    config["missing_scores"] = fields["missing_scores"] if fields["missing_scores"].present?
    config["min_games"] = fields["min_games"].to_i if fields["min_games"].present?
    config["show_individual_standings"] = fields["show_individual_standings"] == "1" if fields.key?("show_individual_standings")

    names = fields["medal_names"].to_s.split(",").map(&:strip).compact_blank
    if names.any?
      points = fields["medal_points"].to_s.split(",").map(&:strip)
      config["medals"] = names.each_with_index.map do |name, index|
        { "name" => name, "points" => (points[index].presence || (names.size - index)).to_s.then { |value| value.include?(".") ? value.to_f : value.to_i },
          "color" => Scoring::Config::DEFAULT_MEDALS.dig(index, "color") || "#78716c" }
      end
    end

    placement = fields["placement_points"].to_s.strip
    if placement.casecmp?("linear")
      config["placement_points"] = "linear"
    elsif placement.present?
      config["placement_points"] = placement.split(",").map { |value| value.strip.include?(".") ? value.to_f : value.to_i }
    end
    config
  end

  def from_config(config)
    {
      preset: config.preset, ranking: config.ranking, missing_scores: config.missing_scores, min_games: config.min_games,
      show_individual_standings: config.show_individual_standings?,
      medal_names: config.medal_names.join(", "),
      medal_points: config.medals.map { |medal| ScoreValue.trim(medal["points"]) }.join(", "),
      placement_points: config.placement_points.nil? ? "linear" : config.placement_points.map { |value| ScoreValue.trim(value) }.join(", ")
    }
  end
end
