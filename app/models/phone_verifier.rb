# Phone sign-in codes. Production uses Twilio Verify (plan section 7.1),
# which sends from Twilio's own registered senders and includes Fraud Guard.
# Development and test use a fake backend (see config/initializers/twilio.rb).
module PhoneVerifier
  Result = Data.define(:ok, :error) do
    def ok? = ok
  end

  mattr_accessor :backend

  module_function

  def available?
    backend&.available? && !Flipper.enabled?(:pause_phone_login)
  end

  def start(phone)
    backend.start(phone)
  end

  def check(phone, code)
    backend.check(phone, code.to_s.gsub(/\D/, ""))
  end
end
