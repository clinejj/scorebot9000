module Scoring
  # Computes standings from plain inputs. Pipeline (plan section 8.2):
  #   1. effective score per game and competitor (attempt policy)
  #   2. team rollup of individual games (team basis)
  #   3. rank each game (competition or dense ties)
  #   4. award medals, placement points and normalized scores (x game weight)
  #   5. standings by the configured method, plus adjustments
  #   6. tiebreakers
  class Engine
    INFINITY = BigDecimal("Infinity")
    NAME_TIEBREAKERS = %w[name name_desc].freeze

    def initialize(config)
      @config = config
    end

    def call(games:, participants:, teams:, entries:, adjustments: [], computed_at: Time.current)
      @games = games.sort_by(&:position)
      @participants = participants
      @teams = teams
      @adjustments = adjustments
      index_entries(entries)

      standings, game_results = compute(@config)
      individual = (compute(@config.with_basis("individual")).first if @config.team_basis? && @config.show_individual_standings?)
      Result.new(config: @config, standings: standings, individual_standings: individual, game_results: game_results, computed_at: computed_at)
    end

    private
      def compute(config)
        competitors = competitors_for(config)
        game_results = @games.map { |game| rank_game(game, competitors, config) }
        [ build_standings(competitors, game_results, config), game_results ]
      end

      # -- Inputs ------------------------------------------------------------

      def index_entries(entries)
        @participant_entries = Hash.new { |hash, key| hash[key] = [] }
        @team_entries = Hash.new { |hash, key| hash[key] = [] }
        entries.each do |entry|
          if entry.participant_id
            @participant_entries[[ entry.game_id, entry.participant_id ]] << entry
          else
            @team_entries[[ entry.game_id, entry.team_id ]] << entry
          end
        end
      end

      def competitors_for(config)
        if config.team_basis?
          @teams.map { |team| Competitor.new(type: "team", id: team.id, public_id: team.public_id, name: team.name, team_id: team.id, color: team.color) }
        else
          @participants.map do |participant|
            color = @teams.find { |team| team.id == participant.team_id }&.color
            Competitor.new(type: "participant", id: participant.id, public_id: participant.public_id, name: participant.name, team_id: participant.team_id, color: color)
          end
        end
      end

      # 1. Effective value of one competitor's attempts in a game.
      def effective(entries, game)
        return nil if entries.empty?

        case game.attempt_policy
        when "best" then game.higher_better? ? entries.map(&:value).max : entries.map(&:value).min
        when "average" then (entries.sum(&:value) / entries.size).round(3)
        else entries.max_by { |entry| entry.created_at }.value
        end
      end

      def participant_value(game, participant_id)
        effective(@participant_entries[[ game.id, participant_id ]], game)
      end

      def team_value(game, team_id)
        effective(@team_entries[[ game.id, team_id ]], game)
      end

      # 2. A competitor's value (and contributors) in a game for this basis.
      def value_for(game, competitor, config)
        if competitor.team?
          return [ team_value(game, competitor.id), [] ] if game.team?

          rollup(game, competitor, config)
        elsif game.team?
          [ competitor.team_id && team_value(game, competitor.team_id), [] ]
        else
          [ participant_value(game, competitor.id), [] ]
        end
      end

      def rollup(game, team, config)
        members = @participants.select { |participant| participant.team_id == team.id }
        scored = members.filter_map do |member|
          value = participant_value(game, member.id)
          Contributor.new(public_id: member.public_id, name: member.name, value: value) if value
        end
        return [ nil, [] ] if scored.empty?

        values = scored.map(&:value)
        values += [ BigDecimal(0) ] * (members.size - scored.size) if config.missing_members == "zero"
        [ aggregate(values, game), scored ]
      end

      def aggregate(values, game)
        best_first = game.higher_better? ? values.sort.reverse : values.sort
        case game.team_aggregation
        when "average" then (values.sum / values.size).round(3)
        when "best" then best_first.first
        when "median" then median(values)
        when "top_n_sum" then best_first.first(game.team_aggregation_n || values.size).sum
        else values.sum
        end
      end

      def median(values)
        sorted = values.sort
        middle = sorted.size / 2
        sorted.size.odd? ? sorted[middle] : ((sorted[middle - 1] + sorted[middle]) / 2).round(3)
      end

      # -- 3 & 4. Rank a game and award it ------------------------------------

      def rank_game(game, competitors, config)
        scored = competitors.filter_map do |competitor|
          value, contributors = value_for(game, competitor, config)
          [ competitor, value, contributors ] if value
        end
        scored.sort_by! { |competitor, value, _| [ game.higher_better? ? -value : value, competitor.name.downcase ] }

        values = scored.map { |_, value, _| value }
        distinct = values.uniq
        medals = config.medals
        weight = BigDecimal(game.weight.to_s)
        low, high = values.minmax

        rows = scored.map do |competitor, value, contributors|
          place = if config.dense?
            distinct.index(value) + 1
          else
            values.count { |other| game.higher_better? ? other > value : other < value } + 1
          end
          medal_index = place - 1 if place <= medals.size
          GameRow.new(
            competitor: competitor, value: value, place: place, medal: medal_index,
            medal_points: medal_index ? medals[medal_index]["points"] * weight : BigDecimal(0),
            placement_points: placement_points_for(place, scored.size, config) * weight,
            normalized: normalize(value, low, high, game),
            contributors: contributors
          )
        end
        GameResult.new(game: game, rows: rows, stats: stats(values, game))
      end

      def placement_points_for(place, ranked_count, config)
        table = config.placement_points
        return BigDecimal(ranked_count - place + 1) if table.nil?

        table[place - 1] || BigDecimal(0)
      end

      def normalize(value, low, high, game)
        return BigDecimal(100) if high == low

        fraction = game.higher_better? ? (value - low) / (high - low) : (high - value) / (high - low)
        (fraction * 100).round(3)
      end

      def stats(values, game)
        return GameStats.new(count: 0, mean: nil, median: nil, best: nil, worst: nil) if values.empty?

        GameStats.new(
          count: values.size, mean: (values.sum / values.size).round(3), median: median(values),
          best: game.higher_better? ? values.max : values.min, worst: game.higher_better? ? values.min : values.max
        )
      end

      # -- 5 & 6. Standings ---------------------------------------------------

      def build_standings(competitors, game_results, config)
        rows = competitors.map { |competitor| standing_row(competitor, game_results, config) }
        sorted = rows.sort { |a, b| compare(a, b, config, include_names: true) }
        assign_places(sorted, config)
      end

      def standing_row(competitor, game_results, config)
        tiers = config.medals.size
        medal_counts = Array.new(tiers, 0)
        medal_total = medal_points = placement_points = BigDecimal(0)
        places = []
        normalized = []
        games_played = 0
        best = nil

        game_results.each do |result|
          weight = BigDecimal(result.game.weight.to_s)
          row = result.rows.find { |game_row| game_row.competitor.id == competitor.id }
          if row
            games_played += 1
            best = [ best, row.place ].compact.min
            if row.medal
              medal_counts[row.medal] += 1
              medal_total += weight
            end
            medal_points += row.medal_points
            placement_points += row.placement_points
            places << [ BigDecimal(row.place), weight ]
            normalized << [ row.normalized, weight ]
          else
            case config.missing_scores
            when "worst_place", "zero"
              places << [ BigDecimal(result.rows.size + 1), weight ]
              normalized << [ BigDecimal(0), weight ]
            end
          end
        end

        adjustment_points = adjustments_for(competitor)
        average_rank = weighted_mean(places)
        normalized_average = weighted_mean(normalized)
        total =
          case config.standings_method
          when "weighted_medals", "medal_table" then medal_points + adjustment_points
          when "medal_count" then medal_total + adjustment_points
          when "placement_points" then placement_points + adjustment_points
          when "average_rank" then average_rank
          when "normalized_average" then normalized_average && normalized_average + adjustment_points
          end
        ranked = %w[average_rank normalized_average].include?(config.standings_method) ? games_played >= [ config.min_games, 1 ].max : true

        StandingRow.new(
          competitor: competitor, place: nil, ranked: ranked, medal_counts: medal_counts, medal_total: medal_total,
          medal_points: medal_points, placement_points: placement_points, average_rank: average_rank,
          normalized_average: normalized_average, adjustment_points: adjustment_points, total: total,
          games_played: games_played, best_place: best
        )
      end

      def adjustments_for(competitor)
        @adjustments.sum(BigDecimal(0)) do |adjustment|
          matches = competitor.team? ? adjustment.team_id == competitor.id : adjustment.participant_id == competitor.id
          matches ? BigDecimal(adjustment.points.to_s) : 0
        end
      end

      def weighted_mean(pairs)
        total_weight = pairs.sum(BigDecimal(0)) { |_, weight| weight }
        return nil if pairs.empty? || total_weight.zero?

        (pairs.sum(BigDecimal(0)) { |value, weight| value * weight } / total_weight).round(3)
      end

      # Compare two standing rows: ranked first, then the method's primary key,
      # then tiebreakers. Name tiebreakers only order display, never places.
      def compare(a, b, config, include_names:)
        result = (a.ranked ? 0 : 1) <=> (b.ranked ? 0 : 1)
        return result unless result.zero?

        result = primary_compare(a, b, config)
        return result unless result.zero?

        config.tiebreakers.each do |tiebreaker|
          next if !include_names && NAME_TIEBREAKERS.include?(tiebreaker)

          result = tiebreak_compare(a, b, tiebreaker)
          return result unless result.zero?
        end
        include_names ? a.competitor.name.downcase <=> b.competitor.name.downcase : 0
      end

      def primary_compare(a, b, config)
        case config.standings_method
        when "medal_table" then b.medal_counts <=> a.medal_counts
        when "average_rank" then (a.total || INFINITY) <=> (b.total || INFINITY)
        else (b.total || -INFINITY) <=> (a.total || -INFINITY)
        end
      end

      def tiebreak_compare(a, b, tiebreaker)
        case tiebreaker
        when "medals" then b.medal_counts <=> a.medal_counts
        when "medal_count" then b.medal_total <=> a.medal_total
        when "points" then (b.medal_points + b.adjustment_points) <=> (a.medal_points + a.adjustment_points)
        when "best_place" then (a.best_place || Float::INFINITY) <=> (b.best_place || Float::INFINITY)
        when "average_rank" then (a.average_rank || INFINITY) <=> (b.average_rank || INFINITY)
        when "games_played" then b.games_played <=> a.games_played
        when "name" then a.competitor.name.downcase <=> b.competitor.name.downcase
        when "name_desc" then b.competitor.name.downcase <=> a.competitor.name.downcase
        else 0
        end
      end

      # Competition-style places over the non-name sort keys; unranked rows
      # get no place.
      def assign_places(sorted, config)
        previous = nil
        sorted.each_with_index.map do |row, index|
          place =
            if !row.ranked then nil
            elsif previous && compare(previous, row, config, include_names: false).zero? then previous.place
            else index + 1
            end
          previous = row.with(place: place)
        end
      end
  end
end
