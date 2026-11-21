module Legacy
  # The agreed "fudge" (plan section 8.5): nudges imported scores so that
  # recomputing a legacy event matches what was announced. Display already
  # uses the captured snapshot; this only makes the raw data agree.
  #
  # For each game, when a team's recomputed total differs from the announced
  # total, one member's score is replaced (old entry voided, new entry with
  # source "reconciliation") so the team sum matches. Differences that remain
  # with identical values (the legacy tie bug) are reported, not forced.
  class Reconciler
    Outcome = Data.define(:changes, :remaining)

    def initialize(event, capture)
      @event = event
      @capture = capture
    end

    def reconcile!(by: nil)
      announced = CapturedResults.new(@capture, @event).to_result
      changes = []

      ApplicationRecord.transaction do
        announced.game_results.each do |game_result|
          game = @event.games.find_by(id: game_result.game.id) or next
          next unless game.scored_by_individual? && game.aggregate_sum?

          game_result.rows.each do |row|
            team = @event.teams.find_by(id: row.competitor.id) or next
            changes.concat(nudge(game, team, row.value, by))
          end
        end
      end

      remaining = CapturedResults.diff(announced, Scoring::Standings.compute(@event.reload))
      Outcome.new(changes: changes, remaining: remaining)
    end

    private
      def nudge(game, team, announced_total, by)
        members = team.participants.to_a
        entries = members.filter_map do |member|
          game.score_entries.active.where(participant: member).order(:created_at).last
        end
        current = entries.sum(BigDecimal(0), &:value)
        delta = announced_total - current
        return [] if delta.zero?

        target = entries.max_by(&:value)
        participant = target&.participant || members.first or return []
        new_value = (target&.value || 0) + delta
        target&.void!(by: by)
        ScoreEntry.create!(game: game, participant: participant, value: new_value, raw_input: new_value.to_s("F"),
          source: "reconciliation", submitted_by_user: by,
          note: "Legacy reconciliation: announced #{team.name} total was #{announced_total.to_i} (recomputed #{current.to_i})")
        [ "#{game.name} / #{team.name}: #{participant.alias_name} #{target&.value.to_i} -> #{new_value.to_i} (team #{current.to_i} -> #{announced_total.to_i})" ]
      end
  end
end
