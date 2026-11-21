module Scoring
  # Validated scoring configuration for an event (stored in events.scoring as
  # JSON). The stored hash names a preset plus any overrides:
  #
  #   { "preset" => "weighted_medals", "ranking" => "dense" }
  #
  # See docs/MIGRATION_PLAN.md section 8.
  class Config
    BASES = %w[team individual].freeze
    RANKINGS = %w[competition dense].freeze
    STANDINGS_METHODS = %w[medal_table weighted_medals medal_count placement_points average_rank normalized_average].freeze
    MISSING_SCORES = %w[ignore worst_place zero].freeze
    MISSING_MEMBERS = %w[ignore zero].freeze
    TIEBREAKERS = %w[medals medal_count points best_place average_rank games_played name name_desc].freeze

    DEFAULT_MEDALS = [
      { "name" => "Gold", "points" => 3, "color" => "#c9a227" },
      { "name" => "Silver", "points" => 2, "color" => "#9ca3af" },
      { "name" => "Bronze", "points" => 1, "color" => "#b8743a" }
    ].freeze

    BASE = {
      "ranking" => "competition",
      "medals" => DEFAULT_MEDALS,
      "standings" => "medal_table",
      "placement_points" => [ 10, 8, 6, 5, 4, 3, 2, 1 ],
      "missing_scores" => "ignore",
      "missing_members" => "ignore",
      "min_games" => 1,
      "tiebreakers" => %w[name],
      "show_individual_standings" => true
    }.freeze

    PRESETS = {
      "olympic" => {
        "label" => "Olympic medal table",
        "description" => "Most golds wins, then silvers, then bronzes.",
        "standings" => "medal_table"
      },
      "weighted_medals" => {
        "label" => "Weighted medals",
        "description" => "Gold 3, silver 2, bronze 1 points; most points wins.",
        "standings" => "weighted_medals",
        "tiebreakers" => %w[medals name]
      },
      "placement_points" => {
        "label" => "Placement points",
        "description" => "Points for every finishing place (10, 8, 6, 5, 4, 3, 2, 1).",
        "standings" => "placement_points",
        "tiebreakers" => %w[medals best_place name]
      },
      "average_rank" => {
        "label" => "Average rank",
        "description" => "Lowest average finishing place wins; skipped games count as last place.",
        "standings" => "average_rank",
        "missing_scores" => "worst_place",
        "tiebreakers" => %w[medals name]
      },
      "normalized_average" => {
        "label" => "Normalized average",
        "description" => "Each game scored 0-100 relative to the best and worst result, then averaged.",
        "standings" => "normalized_average",
        "missing_scores" => "zero",
        "tiebreakers" => %w[medals name]
      },
      # Reproduces the 2012-2021 Java app (plan section 3.2): team totals are
      # summed member scores, dense ranking (ties don't use up medal slots),
      # 3/2/1 weighted medal points, ties broken by medals then reverse name.
      "legacy_clinelympics" => {
        "label" => "Legacy Clinelympics (2012-2021)",
        "description" => "How the original Scorebot scored team events.",
        "basis" => "team",
        "ranking" => "dense",
        "standings" => "weighted_medals",
        "tiebreakers" => %w[medals name_desc],
        "show_individual_standings" => false
      },
      "legacy_clinelympics_individual" => {
        "label" => "Legacy Clinelympics, individual (2012-2021)",
        "description" => "How the original Scorebot scored individual events (unweighted medal counts).",
        "basis" => "individual",
        "ranking" => "dense",
        "standings" => "medal_count",
        "tiebreakers" => %w[medals name_desc]
      }
    }.freeze

    DEFAULT_PRESET = "olympic"

    attr_reader :settings, :errors

    def self.preset_options
      PRESETS.reject { |key, _| key.start_with?("legacy_") }.map { |key, preset| [ preset["label"], key ] }
    end

    # Medal tiers from the legacy CSV ("Gold,Silver,Bronze"), best first.
    def self.medals_from_names(names)
      list = names.to_s.split(",").map(&:strip).compact_blank
      list.each_with_index.map do |name, index|
        { "name" => name, "points" => list.size - index, "color" => DEFAULT_MEDALS.dig(index, "color") || "#78716c" }
      end
    end

    def self.from(stored, uses_teams: true)
      new(stored, uses_teams: uses_teams)
    end

    def initialize(stored = {}, uses_teams: true)
      stored = (stored || {}).deep_stringify_keys
      @preset = PRESETS.key?(stored["preset"]) ? stored["preset"] : DEFAULT_PRESET
      @settings = BASE
        .merge("basis" => uses_teams ? "team" : "individual")
        .merge(PRESETS.fetch(@preset).except("label", "description"))
        .merge(stored.except("preset"))
      @errors = []
      validate
    end

    def preset = @preset
    def preset_label = PRESETS.dig(@preset, "label")
    def basis = settings["basis"]
    def team_basis? = basis == "team"
    def ranking = settings["ranking"]
    def dense? = ranking == "dense"
    def standings_method = settings["standings"]
    def missing_scores = settings["missing_scores"]
    def missing_members = settings["missing_members"]
    def min_games = settings["min_games"].to_i
    def tiebreakers = Array(settings["tiebreakers"])
    def show_individual_standings? = settings["show_individual_standings"] == true

    def medals
      Array(settings["medals"]).map do |medal|
        medal = medal.stringify_keys
        { "name" => medal["name"].to_s, "points" => BigDecimal(medal["points"].to_s), "color" => medal["color"] }
      end
    end

    def medal_names = medals.map { |medal| medal["name"] }

    # nil means "linear": N - place + 1 where N is the number ranked.
    def placement_points
      value = settings["placement_points"]
      value == "linear" ? nil : Array(value).map { |points| BigDecimal(points.to_s) }
    end

    def valid? = errors.empty?

    def to_h
      settings.merge("preset" => @preset)
    end

    def digest
      Digest::SHA256.hexdigest(to_h.to_json)
    end

    # Same config with a different basis (used for individual standings).
    def with_basis(new_basis)
      self.class.new(to_h.merge("basis" => new_basis))
    end

    private
      def validate
        @errors << "basis must be one of #{BASES.join(", ")}" unless BASES.include?(basis)
        @errors << "ranking must be one of #{RANKINGS.join(", ")}" unless RANKINGS.include?(ranking)
        @errors << "standings must be one of #{STANDINGS_METHODS.join(", ")}" unless STANDINGS_METHODS.include?(standings_method)
        @errors << "missing_scores must be one of #{MISSING_SCORES.join(", ")}" unless MISSING_SCORES.include?(missing_scores)
        @errors << "missing_members must be one of #{MISSING_MEMBERS.join(", ")}" unless MISSING_MEMBERS.include?(missing_members)
        unknown = tiebreakers - TIEBREAKERS
        @errors << "unknown tiebreakers: #{unknown.join(", ")}" if unknown.any?
        validate_medals
        validate_placement_points
      end

      def validate_medals
        list = Array(settings["medals"])
        return @errors << "medals must be a list" unless settings["medals"].is_a?(Array)
        return @errors << "at most 10 medal tiers" if list.size > 10

        list.each do |medal|
          unless medal.is_a?(Hash) && medal["name"].present? && numeric?(medal["points"])
            @errors << "each medal needs a name and numeric points"
            break
          end
        end
      end

      def validate_placement_points
        value = settings["placement_points"]
        return if value == "linear"

        unless value.is_a?(Array) && value.all? { |points| numeric?(points) }
          @errors << "placement_points must be a list of numbers or \"linear\""
        end
      end

      def numeric?(value)
        BigDecimal(value.to_s)
        true
      rescue ArgumentError, TypeError
        false
      end
  end
end
