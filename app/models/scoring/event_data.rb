module Scoring
  # Loads an event from the database into plain engine inputs.
  class EventData
    def self.load(event)
      games = event.games.to_a
      {
        games: games.map do |game|
          GameInput.new(id: game.id, public_id: game.public_id, name: game.name, position: game.position, direction: game.direction,
            participation: game.participation, team_aggregation: game.team_aggregation, team_aggregation_n: game.team_aggregation_n,
            attempt_policy: game.attempt_policy, weight: game.weight, score_format: game.score_format)
        end,
        participants: event.participants.map do |participant|
          ParticipantInput.new(id: participant.id, public_id: participant.public_id, name: participant.alias_name, team_id: participant.team_id)
        end,
        teams: event.teams.map { |team| TeamInput.new(id: team.id, public_id: team.public_id, name: team.name, color: team.color) },
        entries: ScoreEntry.active.where(game_id: games.map(&:id))
          .pluck(:game_id, :participant_id, :team_id, :value, :created_at)
          .map { |game_id, participant_id, team_id, value, created_at| EntryInput.new(game_id:, participant_id:, team_id:, value:, created_at:) },
        adjustments: event.adjustments.map do |adjustment|
          AdjustmentInput.new(participant_id: adjustment.participant_id, team_id: adjustment.team_id, points: adjustment.points, reason: adjustment.reason)
        end
      }
    end
  end
end
