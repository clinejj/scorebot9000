module Sms
  # Processes one inbound text and returns the reply text (or nil for no
  # reply). Used by the Twilio webhook and the admin/organizer simulator.
  #
  # Every inbound message and reply is logged in sms_messages. Twilio retries
  # (same MessageSid) return the original reply without reprocessing.
  class Inbound
    Outcome = Data.define(:reply, :message)

    def self.call(**)
      new(**).call
    end

    def initialize(from:, body:, to: nil, sid: nil, simulated: false)
      @from = PhoneNumber.normalize(from) || from.to_s.strip
      @to = to
      @body = body.to_s
      @sid = sid.presence
      @simulated = simulated
    end

    def call
      if @sid && (existing = SmsMessage.find_by(twilio_sid: @sid))
        return Outcome.new(reply: existing.reply&.body, message: existing)
      end

      @message = SmsMessage.create!(direction: "inbound", twilio_sid: @sid, from_number: @from, to_number: @to,
        body: @body.first(1600), simulated: @simulated, status: "received")

      if Flipper.enabled?(:pause_sms_inbound)
        @message.update!(status: "paused")
        return Outcome.new(reply: nil, message: @message)
      end

      reply = process
      log_reply(reply)
      Outcome.new(reply: reply, message: @message)
    rescue StandardError => error
      Rails.error.report(error, context: { sms_message_id: @message&.id })
      @message&.update(status: "error", error: "#{error.class}: #{error.message}".first(255))
      Outcome.new(reply: "Sorry, something went wrong. Try again in a minute.", message: @message)
    end

    private
      def process
        command = CommandParser.parse(@body)
        @message.update!(command: command.name.to_s)

        case command.name
        when :carrier_keyword, :empty then return nil
        when :commands then return Replies.commands
        end

        return "Sorry, that number can't be used here." unless PhoneNumber.valid?(@from)

        user = User.find_by(phone: @from)
        event = admin_target_event(command) || EventRouter.resolve(user: user, command: command)
        @message.update!(user: user, event: event)
        return Replies.which_event(command, known_sender: user.present?) if event.nil?
        return "Texting isn't turned on for #{event.name}. Play on the event page instead." unless event.sms_scoring_enabled? || command.name == :admin

        return register_new_sender(event, command) if user.nil?

        Commands.new(event: event, user: user, command: command).run
      end

      # A number we haven't seen only gets an account when it registers for
      # an event that's taking registrations. Anything else gets a pointer to
      # REGISTER, and nothing is stored beyond the message log.
      def register_new_sender(event, command)
        return Replies.unknown if command.name == :admin
        return Replies.not_registered(event) unless command.name.in?(%i[register join])

        reply = nil
        user = nil
        User.transaction do
          user = User.create!(phone: @from, sms_context_event: (event if command.name == :join))
          reply = Commands.new(event: event, user: user, command: command).run
          raise ActiveRecord::Rollback unless event.participants.exists?(user: user)
        end
        @message.update!(user: user) if user&.persisted?
        reply
      end

      # ADMIN START <code> can target an event that isn't live yet.
      def admin_target_event(command)
        return unless command.name == :admin && command.arg(:value)

        Event.find_by(sms_code: command.arg(:value).upcase)
      end

      def log_reply(reply)
        @message.update!(status: "processed")
        return if reply.blank?

        SmsMessage.create!(direction: "outbound", body: reply, to_number: @from, from_number: @to, user: @message.user,
          event: @message.event, reply_to: @message, simulated: @simulated, status: "replied")
      end
  end
end
