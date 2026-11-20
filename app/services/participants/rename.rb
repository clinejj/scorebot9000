module Participants
  # Changes a participant's alias: to a chosen name (if the event allows
  # overrides) or to a new random alias.
  class Rename
    Result = Data.define(:participant, :error) do
      def success? = error.nil?
    end

    def self.call(participant:, alias_name: nil)
      event = participant.event
      requested = alias_name.to_s.squish.presence

      if requested
        return Result.new(participant, "Custom names aren't allowed for this event.") unless event.allow_alias_override? || !event.aliases_random?

        participant.update(alias_name: requested, alias_source: "chosen") ? Result.new(participant, nil) : Result.new(participant, participant.errors.full_messages.to_sentence)
      else
        participant.update!(alias_name: AliasPicker.new(event).pick, alias_source: "random")
        Result.new(participant, nil)
      end
    end
  end
end
