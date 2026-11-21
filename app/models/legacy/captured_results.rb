module Legacy
  # Results as the legacy site displayed them, captured from summary.jsp by
  # script/legacy/capture_results.rb into db/legacy_results/event_N.json.
  # These become the official snapshots: what was shown and announced wins.
  #
  # Capture format: every <h3>-titled table on the page, keyed by a
  # normalized heading ("team_medal_count", "team_medals", "team_scores",
  # "player_medal_count", "player_medals"), each { "headers" => [...], "rows" => [[...]] }.
  class CapturedResults
    DIRECTORY = Rails.root.join("db/legacy_results")

    def self.load_all(directory = DIRECTORY)
      Dir.glob(File.join(directory, "event_*.json")).to_h do |path|
        data = JSON.parse(File.read(path))
        [ data.fetch("legacy_event_id").to_i, data ]
      end
    end

    # Differences between the announced and recomputed standings, as strings.
    def self.diff(announced, computed)
      diffs = []
      computed_by_name = computed.standings.index_by { |row| row.competitor.name.downcase }
      announced.standings.each do |row|
        other = computed_by_name[row.competitor.name.downcase]
        if other.nil?
          diffs << "#{row.competitor.name}: shown in the legacy results but not found in the imported data"
          next
        end
        diffs << "#{row.competitor.name}: place #{row.place} shown, #{other.place} recomputed" if row.place != other.place
        diffs << "#{row.competitor.name}: #{row.total.to_i} points shown, #{other.total.to_i} recomputed" if row.total.to_i != other.total.to_i
        diffs << "#{row.competitor.name}: medals #{row.medal_counts.join("/")} shown, #{other.medal_counts.join("/")} recomputed" if row.medal_counts != other.medal_counts
      end
      announced.game_results.each do |game_result|
        other = computed.game_results.find { |result| result.game.name.casecmp?(game_result.game.name) } or next
        game_result.rows.each do |row|
          match = other.rows.find { |candidate| candidate.competitor.name.casecmp?(row.competitor.name) }
          next unless match
          diffs << "#{game_result.game.name} / #{row.competitor.name}: #{row.value.to_i} shown, #{match.value.to_i} recomputed" if row.value != match.value
          diffs << "#{game_result.game.name} / #{row.competitor.name}: #{medal_name(row.medal, announced)} shown, #{medal_name(match.medal, computed)} recomputed" if row.medal != match.medal
        end
      end
      diffs
    end

    def self.medal_name(index, result)
      index.nil? ? "no medal" : result.config.medal_names[index]
    end

    def initialize(data, event)
      @data = data
      @tables = data.fetch("tables")
      @event = event
      @config = event.scoring_config
    end

    def team_basis?
      @tables.key?("team_medal_count") || @tables.key?("team_scores")
    end

    def to_result
      Scoring::Result.new(
        config: @config,
        standings: standings,
        individual_standings: nil,
        game_results: game_results,
        computed_at: @data["captured_at"] ? Time.iso8601(@data["captured_at"]) : Time.current
      )
    end

    private
      def prefix = team_basis? ? "team" : "player"

      def standings
        table = @tables["#{prefix}_medal_count"] or return []
        tiers = @config.medals.size
        previous = nil
        table["rows"].each_with_index.map do |cells, index|
          name = cells.first.to_s.squish
          # Player tables have a Team column after the name when the event used teams.
          numbers = cells.last(tiers + 1).map { |cell| cell.to_s.strip.to_i }
          medal_counts = numbers.first(tiers)
          total = BigDecimal(numbers.last)
          place = previous && previous.total == total && previous.medal_counts == medal_counts ? previous.place : index + 1
          previous = Scoring::StandingRow.new(
            competitor: competitor(name), place: place, ranked: true, medal_counts: medal_counts,
            medal_total: BigDecimal(medal_counts.sum), medal_points: total, placement_points: BigDecimal(0),
            average_rank: nil, normalized_average: nil, adjustment_points: BigDecimal(0), total: total,
            games_played: nil, best_place: nil
          )
        end
      end

      def game_results
        scores = @tables["team_scores"] if team_basis?
        medals_table = @tables["#{prefix}_medals"]
        game_names = (scores || medals_table)&.dig("headers")&.drop(1) || []

        game_names.each_with_index.map do |game_name, column|
          game = @event.games.find { |candidate| candidate.name.casecmp?(game_name.to_s.squish) } || @event.games[column]
          values = values_for(scores, column, medals_table)
          medal_of = medalists(medals_table, column)
          ordered = values.sort_by { |name, value| [ medal_of[name.downcase] || 99, game&.lower_better? ? value : -value ] }
          distinct = ordered.map(&:last).uniq
          if game&.lower_better? then distinct.sort! else distinct.sort!.reverse! end

          rows = ordered.map do |name, value|
            medal = medal_of[name.downcase]
            place = medal ? medal + 1 : distinct.index(value) + 1
            Scoring::GameRow.new(
              competitor: competitor(name), value: value, place: place, medal: medal,
              medal_points: medal ? @config.medals[medal]["points"] : BigDecimal(0), placement_points: BigDecimal(0),
              normalized: nil, contributors: []
            )
          end
          Scoring::GameResult.new(game: game_input(game, game_name, column), rows: rows, stats: stats(values.map(&:last), game))
        end
      end

      # name => value. Team events have a full scores table; otherwise use the
      # values shown next to medalists.
      def values_for(scores, column, medals_table)
        if scores
          scores["rows"].filter_map do |cells|
            raw = cells[column + 1].to_s.strip
            [ cells.first.to_s.squish, BigDecimal(raw) ] if raw.match?(/\A-?\d+(\.\d+)?\z/)
          end
        else
          medals_table["rows"].flat_map do |cells|
            names, value = parse_medal_cell(cells[column + 1])
            names.map { |name| [ name, value ] }
          end.compact.uniq
        end
      end

      # lower(name) => medal tier index, from cells like "BEARS, ANTS: 10".
      def medalists(table, column)
        return {} unless table

        table["rows"].each_with_index.each_with_object({}) do |(cells, tier), medals|
          names, = parse_medal_cell(cells[column + 1])
          names.each { |name| medals[name.downcase] ||= tier }
        end
      end

      def parse_medal_cell(cell)
        text = cell.to_s.strip
        return [ [], nil ] if text.empty?

        names, value = text.rpartition(":").values_at(0, 2)
        [ names.split(", ").map(&:squish).compact_blank, BigDecimal(value.strip) ]
      rescue ArgumentError
        [ [], nil ]
      end

      def competitor(name)
        @competitors ||= {}
        @competitors[name.downcase] ||= begin
          record = team_basis? ? @event.teams.find_by_name(name) : @event.participants.find_by("lower(alias_name) = ?", name.downcase)
          type = team_basis? ? "team" : "participant"
          Scoring::Competitor.new(type: type, id: record&.id, public_id: record&.public_id,
            name: record&.then { |r| team_basis? ? r.name : r.alias_name } || name.titleize,
            team_id: team_basis? ? record&.id : record&.team_id, color: team_basis? ? record&.color : nil)
        end
      end

      def game_input(game, name, column)
        Scoring::GameInput.new(
          id: game&.id, public_id: game&.public_id, name: game&.name || name, position: game&.position || column + 1,
          direction: game&.direction || "higher_better", participation: game&.participation || "individual",
          team_aggregation: game&.team_aggregation || "sum", team_aggregation_n: nil, attempt_policy: game&.attempt_policy || "latest",
          weight: game&.weight || BigDecimal(1), score_format: game&.score_format || "integer"
        )
      end

      def stats(values, game)
        return Scoring::GameStats.new(count: 0, mean: nil, median: nil, best: nil, worst: nil) if values.empty?

        sorted = values.sort
        middle = sorted.size / 2
        median = sorted.size.odd? ? sorted[middle] : (sorted[middle - 1] + sorted[middle]) / 2
        lower = game&.lower_better?
        Scoring::GameStats.new(count: values.size, mean: (values.sum / values.size).round(3), median: median,
          best: lower ? sorted.first : sorted.last, worst: lower ? sorted.last : sorted.first)
      end
  end
end
