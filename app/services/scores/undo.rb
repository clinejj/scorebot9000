module Scores
  # Voids a participant's most recent active submission in an event
  # (including team-game scores they submitted for their team).
  class Undo
    def self.call(participant:, by: participant.user)
      entry = ScoreEntry.active.joins(:game).where(games: { event_id: participant.event_id })
        .where("score_entries.participant_id = :participant OR (score_entries.team_id IS NOT NULL AND score_entries.submitted_by_user_id = :user)",
               participant: participant.id, user: participant.user_id)
        .order(created_at: :desc).first
      entry&.void!(by: by)
      entry
    end
  end
end
