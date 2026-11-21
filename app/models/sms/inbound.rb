module Sms
  # Processes one inbound text and returns the reply text (or nil for no
  # reply). Used by the Twilio webhook and the admin/organizer simulator.
  #
  # Every inbound message and reply is logged in sms_messages. Twilio retries
  # (same MessageSid) return the original reply without reprocessing.
  class Inbound
    Outcome = Data.define(:reply, :message)

    # Cost guards (plan section 9.5): texts beyond these get processed-but-no-reply.
    SENDER_LIMIT = 30           # inbound texts per number per 10 minutes
    SENDER_WINDOW = 10.minutes

    # Twilio's A2P 10DLC limit for a Sole Proprietor brand is 1,000 segments
    # a day to T-Mobile (about 3,000 across US carriers), reset at midnight
    # Pacific. Every event shares the one number, so the cap is platform-wide.
    REPLY_CAP_TIME_ZONE = "America/Los_Angeles"

    def self.daily_reply_cap
      ENV.fetch("SMS_DAILY_REPLY_CAP", 1000).to_i
    end

    def self.call(**)
      new(**).call
    end

    # route_to: an event to route to instead of the usual rules (the
    # organizer simulator passes its event). JOIN <code> still wins.
    def initialize(from:, body:, to: nil, sid: nil, simulated: false, route_to: nil)
      @from = PhoneNumber.normalize(from) || from.to_s.strip
      @to = to
      @body = body.to_s
      @sid = sid.presence
      @simulated = simulated
      @route_to = route_to
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

      if sender_rate_limited?
        @message.update!(status: "rate_limited")
        return Outcome.new(reply: nil, message: @message)
      end

      reply = process
      if reply.present? && reply_cap_reached?
        @message.update!(status: "capped")
        Rails.logger.warn("SMS daily reply cap (#{self.class.daily_reply_cap}) reached")
        return Outcome.new(reply: nil, message: @message)
      end
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
        event = admin_target_event(command) || routed_event(command) || EventRouter.resolve(user: user, command: command)
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

      def routed_event(command)
        @route_to unless command.name == :join
      end

      def sender_rate_limited?
        return false if @simulated

        SmsMessage.inbound.where(from_number: @from, simulated: false).where(created_at: SENDER_WINDOW.ago..).count > SENDER_LIMIT
      end

      def reply_cap_reached?
        return false if @simulated

        day_start = Time.current.in_time_zone(REPLY_CAP_TIME_ZONE).beginning_of_day
        SmsMessage.outbound.where(simulated: false, created_at: day_start..).count >= self.class.daily_reply_cap
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
