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

    def self.daily_reply_cap
      ENV.fetch("SMS_DAILY_REPLY_CAP_PER_EVENT", 2000).to_i
    end

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

      if sender_rate_limited?
        @message.update!(status: "rate_limited")
        return Outcome.new(reply: nil, message: @message)
      end

      reply = process
      if reply.present? && reply_cap_reached?
        @message.update!(status: "capped")
        Rails.logger.warn("SMS reply cap reached for event #{@message.event&.public_id}")
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

        user = User.find_by(phone: @from) || User.create!(phone: @from)
        @message.update!(user: user)

        event = admin_target_event(command) || EventRouter.resolve(user: user, command: command)
        @message.update!(event: event)
        return Replies.which_event(command) if event.nil?
        return "Texting isn't turned on for #{event.name}. Play on the event page instead." unless event.sms_scoring_enabled? || command.name == :admin

        Commands.new(event: event, user: user, command: command).run
      end

      def sender_rate_limited?
        return false if @simulated

        SmsMessage.inbound.where(from_number: @from, simulated: false).where(created_at: SENDER_WINDOW.ago..).count > SENDER_LIMIT
      end

      def reply_cap_reached?
        return false if @simulated || @message.event_id.nil?

        SmsMessage.outbound.where(event_id: @message.event_id, simulated: false)
          .where(created_at: Time.current.beginning_of_day..).count >= self.class.daily_reply_cap
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
