# Twilio inbound SMS webhook (plan section 9.1). Inherits ActionController::Base
# directly: Twilio isn't a browser, so allow_browser and CSRF don't apply.
# Every request must carry a valid X-Twilio-Signature.
class SmsWebhooksController < ActionController::Base
  skip_forgery_protection
  before_action :verify_twilio_signature

  def create
    outcome = Sms::Inbound.call(from: params[:From], to: params[:To], body: params[:Body], sid: params[:MessageSid])
    render xml: Sms::Twiml.reply(outcome.reply)
  end

  private
    def verify_twilio_signature
      token = Rails.configuration.x.twilio.auth_token
      return head(:service_unavailable) if token.blank?

      validator = Twilio::Security::RequestValidator.new(token)
      head :forbidden unless validator.validate(request.original_url, request.POST, request.headers["X-Twilio-Signature"].to_s)
    end
end
