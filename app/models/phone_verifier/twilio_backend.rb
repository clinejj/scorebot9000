module PhoneVerifier
  class TwilioBackend
    def initialize(account_sid:, auth_token:, service_sid:)
      @account_sid = account_sid
      @auth_token = auth_token
      @service_sid = service_sid
    end

    def available?
      [ @account_sid, @auth_token, @service_sid ].all?(&:present?)
    end

    def start(phone)
      service.verifications.create(to: phone, channel: "sms")
      Result.new(ok: true, error: nil)
    rescue Twilio::REST::RestError => error
      Rails.logger.warn("Twilio Verify start failed: #{error.code} #{error.message}")
      Result.new(ok: false, error: "We couldn't text that number. Check it and try again, or use your email.")
    end

    def check(phone, code)
      check = service.verification_checks.create(to: phone, code: code)
      check.status == "approved" ? Result.new(ok: true, error: nil) : Result.new(ok: false, error: "That code didn't match. Try again.")
    rescue Twilio::REST::RestError => error
      Rails.logger.warn("Twilio Verify check failed: #{error.code} #{error.message}")
      Result.new(ok: false, error: "That code has expired. Request a new one.")
    end

    private
      def service
        Twilio::REST::Client.new(@account_sid, @auth_token).verify.v2.services(@service_sid)
      end
  end
end
