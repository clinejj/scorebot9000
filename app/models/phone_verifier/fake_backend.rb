module PhoneVerifier
  # Development/test stand-in for Twilio Verify. Codes live in memory; in
  # development they're logged (and shown on screen) instead of texted.
  class FakeBackend
    TEST_CODE = "424242"

    def initialize(code: nil)
      @fixed_code = code
      @codes = {}
      @mutex = Mutex.new
    end

    def available? = true

    def start(phone)
      code = @fixed_code || format("%06d", SecureRandom.random_number(1_000_000))
      @mutex.synchronize { @codes[phone] = code }
      Rails.logger.info("[PhoneVerifier] code for #{PhoneNumber.mask(phone)}: #{code}")
      Result.new(ok: true, error: nil)
    end

    def check(phone, code)
      expected = @mutex.synchronize { @codes[phone] }
      if expected && ActiveSupport::SecurityUtils.secure_compare(expected, code)
        @mutex.synchronize { @codes.delete(phone) }
        Result.new(ok: true, error: nil)
      else
        Result.new(ok: false, error: "That code didn't match. Try again.")
      end
    end

    def last_code_for(phone)
      @mutex.synchronize { @codes[phone] }
    end
  end
end
