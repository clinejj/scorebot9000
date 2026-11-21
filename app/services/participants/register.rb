module Participants
  # Registers a user for an event (from SMS, the web, or an organizer).
  # Idempotent: an existing registration is returned as-is.
  class Register
    Result = Data.define(:participant, :created, :error) do
      def success? = error.nil?
    end

    def self.call(**)
      new(**).call
    end

    def initialize(event:, user:, team_name: nil, alias_name: nil, via: :web, force: false)
      @event = event
      @user = user
      @team_name = team_name.to_s.squish.presence
      @alias_name = alias_name.to_s.squish.presence
      @via = via.to_s
      @force = force # organizers can register people while registration is closed
    end

    def call
      existing = @event.participant_for(@user)
      return Result.new(existing, false, nil) if existing
      return Result.new(nil, false, "Registration is closed for #{@event.name}.") unless @force || @event.accepting_registrations?
      if @event.teams_self_registered? && @team_name.nil? && @via == "sms"
        return Result.new(nil, false, "Include a team name, like: REGISTER WHEATIES")
      end

      participant = nil
      # requires_new: a savepoint, so the rollback below also works when the
      # caller already has a transaction open (SMS sign-up from a new number).
      ApplicationRecord.transaction(requires_new: true) do
        participant = create_participant!
        if @team_name && @event.uses_teams?
          joined = Teams::Join.call(participant: participant, team_name: @team_name)
          unless joined.success?
            @team_error = joined.error
            raise ActiveRecord::Rollback
          end
        end
      end
      return Result.new(nil, false, @team_error) if @team_error

      Result.new(participant, true, nil)
    rescue ActiveRecord::RecordInvalid => error
      Result.new(nil, false, error.record.errors.full_messages.to_sentence)
    end

    private
      def create_participant!
        attempts = 0
        begin
          attempts += 1
          name, source = alias_and_source
          @event.participants.create!(user: @user, alias_name: name, alias_source: source, registered_via: @via)
        rescue ActiveRecord::RecordNotUnique
          # Two registrations raced for the same random alias; pick again.
          raise if attempts >= 5 || source != "random"

          retry
        end
      end

      def alias_and_source
        chosen = @alias_name if @alias_name && (@event.allow_alias_override? || !@event.aliases_random?)
        if chosen
          [ chosen, "chosen" ]
        elsif @event.aliases_real_name? && @user.name.present?
          [ @user.name, "real_name" ]
        elsif @event.aliases_self_chosen? && @user.name.present?
          [ @user.name, "chosen" ]
        else
          [ AliasPicker.new(@event).pick, "random" ]
        end
      end
  end
end
