module Sms
  module Twiml
    module_function

    def reply(text)
      Twilio::TwiML::MessagingResponse.new do |response|
        response.message(body: text) if text.present?
      end.to_s
    end
  end
end
