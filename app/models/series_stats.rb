# All-time stats for a series, from each finished event's official results:
# champions by edition, an all-time medal table by person (team medals count
# for every member), and records for games that recur across editions.
#
# People are shown by their most recent alias, never by contact details.
class SeriesStats
  Champion = Data.define(:event, :names)
  PersonRow = Data.define(:user_id, :name, :medal_counts, :events_played)
  Record = Data.define(:game_name, :value, :format, :holder, :event)

  def initialize(series)
    @series = series
  end

  def finished_events
    @finished_events ||= @series.events.where(status: %w[final archived]).includes(:official_snapshot)
      .select(&:official_snapshot).sort_by { |event| event.starts_at || event.created_at }.reverse
  end

  def champions
    finished_events.filter_map do |event|
      winners = results_for(event).standings.select { |row| row.place == 1 }
      Champion.new(event: event, names: winners.map { |row| row.competitor.name }) if winners.any?
    end
  end

  def medal_names
    finished_events.first&.scoring_config&.medal_names || Scoring::Config::DEFAULT_MEDALS.map { |medal| medal["name"] }
  end

  def all_time_medals(limit: 25)
    tiers = medal_names.size
    counts = Hash.new { |hash, user_id| hash[user_id] = Array.new(tiers, 0) }
    events_played = Hash.new { |hash, user_id| hash[user_id] = Set.new }

    finished_events.each do |event|
      members = members_by_competitor(event)
      members.each_value { |user_ids| user_ids.each { |user_id| events_played[user_id] << event.id } }
      results_for(event).game_results.each do |game_result|
        game_result.rows.each do |row|
          next if row.medal.nil? || row.medal >= tiers

          Array(members[row.competitor.id]).each { |user_id| counts[user_id][row.medal] += 1 }
        end
      end
    end

    names = latest_aliases(counts.keys)
    counts.map { |user_id, medal_counts| PersonRow.new(user_id: user_id, name: names[user_id], medal_counts: medal_counts, events_played: events_played[user_id].size) }
      .sort_by { |row| [ row.medal_counts.map(&:-@), row.name.to_s.downcase ] }
      .first(limit)
  end

  def records
    best = {}
    finished_events.each do |event|
      results_for(event).game_results.each do |game_result|
        top = game_result.rows.min_by(&:place) or next
        key = game_result.game.name.downcase.squish
        current = best[key]
        better = current.nil? || (game_result.game.higher_better? ? top.value > current.value : top.value < current.value)
        if better
          best[key] = Record.new(game_name: game_result.game.name, value: top.value, format: game_result.game.score_format,
            holder: top.competitor.name, event: event)
        end
      end
    end
    counts = finished_events.flat_map { |event| results_for(event).game_results.map { |result| result.game.name.downcase.squish } }.tally
    best.select { |key, _| counts[key] > 1 }.values.sort_by(&:game_name)
  end

  private
    def results_for(event)
      @results ||= {}
      @results[event.id] ||= Scoring::Serializer.load(event.official_snapshot.standings_payload)
    end

    # competitor id (team or participant) => [user_id, ...]
    def members_by_competitor(event)
      event.participants.pluck(:id, :team_id, :user_id).each_with_object(Hash.new { |hash, key| hash[key] = [] }) do |(id, team_id, user_id), map|
        map[id] << user_id
        map[team_id] << user_id if team_id
      end
    end

    def latest_aliases(user_ids)
      Participant.joins(:event).where(user_id: user_ids, events: { series_id: @series.id })
        .order("events.starts_at DESC NULLS LAST").pluck(:user_id, :alias_name)
        .each_with_object({}) { |(user_id, alias_name), names| names[user_id] ||= alias_name }
    end
end
