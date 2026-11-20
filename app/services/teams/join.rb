module Teams
  # Puts a participant on a team by name, creating the team if needed (for
  # events with self-registered teams). Enforces the event's max team size.
  class Join
    Result = Data.define(:team, :error) do
      def success? = error.nil?
    end

    def self.call(participant:, team_name:)
      new(participant, team_name).call
    end

    def initialize(participant, team_name)
      @participant = participant
      @team_name = team_name.to_s.squish
    end

    def call
      event = @participant.event
      return Result.new(nil, "This event doesn't use teams.") unless event.uses_teams?
      return Result.new(nil, "Team name can't be blank.") if @team_name.blank?
      return Result.new(nil, "Team name is too long (60 characters max).") if @team_name.length > 60

      team = event.teams.find_by_name(@team_name)
      if team.nil?
        return Result.new(nil, "Teams are assigned by the organizers for this event.") unless event.teams_self_registered?

        team = create_team(event)
      end
      return Result.new(team, nil) if @participant.team_id == team.id
      return Result.new(nil, "Team #{team.name} is full.") if team.full?

      @participant.update!(team: team)
      Result.new(team, nil)
    end

    private
      def create_team(event)
        event.teams.create!(name: @team_name)
      rescue ActiveRecord::RecordNotUnique, ActiveRecord::RecordInvalid
        event.teams.find_by_name(@team_name) || raise
      end
  end
end
