module Scores
  # Records a score for a game. `competitor` is a Participant or a Team; for
  # team-scored games a participant's score is recorded for their team.
  class Submit
    Result = Data.define(:entry, :error) do
      def success? = error.nil?
    end

    def self.call(**)
      new(**).call
    end

    def initialize(game:, competitor:, raw_value:, source:, submitted_by: nil, note: nil, as_organizer: false)
      @game = game
      @competitor = competitor
      @raw_value = raw_value.to_s.strip
      @source = source.to_s
      @submitted_by = submitted_by
      @note = note
      @as_organizer = as_organizer
    end

    def call
      return failure("#{@game.event.name} is finished; scores are final.") if @game.event.finished?
      unless @as_organizer || @game.open_for_players?
        return failure(@game.event.live? ? "Game #{@game.position} (#{@game.name}) isn't accepting scores right now." : "#{@game.event.name} isn't live yet.")
      end

      value = @game.parse_value(@raw_value)
      return failure("Couldn't read \"#{@raw_value}\" as a score for #{@game.name}. Send #{@game.score_hint}.") if value.nil?

      participant, team = resolve_competitor
      return failure(@error) if @error

      entry = ScoreEntry.create!(
        game: @game, participant: participant, team: team, value: value, raw_input: @raw_value.first(100),
        source: @source, note: @note, submitted_by_user: @submitted_by
      )
      Result.new(entry, nil)
    rescue ActiveRecord::RecordInvalid => error
      failure(error.record.errors.full_messages.to_sentence)
    end

    private
      def resolve_competitor
        case @competitor
        when Team
          @game.scored_by_team? ? [ nil, @competitor ] : (@error = "#{@game.name} is scored per player.") && [ nil, nil ]
        when Participant
          if @game.scored_by_team?
            team = @competitor.team
            @error = "Join a team first: #{@game.name} is a team game." unless team
            [ nil, team ]
          else
            [ @competitor, nil ]
          end
        else
          @error = "Unknown competitor."
          [ nil, nil ]
        end
      end

      def failure(message)
        Result.new(nil, message)
      end
  end
end
