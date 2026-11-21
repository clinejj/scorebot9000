module Sms
  # Decides which event an inbound text is about (plan section 9.2):
  #   1. JOIN <code> (sets the sender's SMS context)
  #   2. the sender's SMS context event, while it's active
  #   3. the one active event the sender is registered for
  #   4. the one active, SMS-enabled event on the platform
  # Otherwise nil, and the reply asks the sender to JOIN with a code.
  #
  # The sender may be nil (a number we haven't seen); then only steps 1 and 4
  # apply.
  class EventRouter
    def self.active_events
      Event.where(status: "live").or(Event.where(status: "published", registration_open: true))
    end

    def self.resolve(user:, command:)
      if command.name == :join
        event = Event.find_by(sms_code: command.arg(:code)) if command.arg(:code)
        user&.update!(sms_context_event: event) if event
        return event
      end

      active = active_events
      return single_sms_event(active) if user.nil?

      if user.sms_context_event_id && (context = active.find_by(id: user.sms_context_event_id))
        return context
      end

      mine = active.where(id: user.participants.select(:event_id)).to_a
      return mine.first if mine.one?
      return nil if mine.many?

      single_sms_event(active)
    end

    def self.single_sms_event(active)
      enabled = active.to_a.select(&:sms_scoring_enabled?)
      enabled.one? ? enabled.first : nil
    end
    private_class_method :single_sms_event
  end
end
