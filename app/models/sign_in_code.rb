# One-time 6-digit codes for email sign-in (phone codes go through Twilio
# Verify). Only a digest is stored; the plaintext code exists in memory long
# enough to be emailed. Codes expire after 10 minutes or 5 wrong guesses, and
# issuing a new code expires earlier ones for the same email.
class SignInCode < ApplicationRecord
  TTL = 10.minutes
  MAX_ATTEMPTS = 5

  encrypts :email, deterministic: true
  normalizes :email, with: ->(email) { email.strip.downcase }

  attr_reader :code

  scope :usable, -> { where(consumed_at: nil).where(expires_at: Time.current..).where(attempts: ...MAX_ATTEMPTS) }

  def self.issue!(email:, ip_address: nil)
    code = format("%06d", SecureRandom.random_number(1_000_000))
    transaction do
      where(email: email).usable.update_all(expires_at: Time.current)
      create!(email: email, ip_address: ip_address, code_digest: digest(code), expires_at: TTL.from_now)
        .tap { |record| record.instance_variable_set(:@code, code) }
    end
  end

  def self.latest_usable_for(email)
    where(email: email).usable.order(created_at: :desc).first
  end

  def self.digest(code)
    OpenSSL::HMAC.hexdigest("SHA256", digest_key, code.to_s.gsub(/\D/, ""))
  end

  def self.digest_key
    Rails.application.key_generator.generate_key("sign_in_codes", 32)
  end

  def self.find_by_magic_link_token(token)
    find_signed(token, purpose: :magic_link)
  end

  def usable?
    consumed_at.nil? && expires_at.future? && attempts < MAX_ATTEMPTS
  end

  # Returns true and consumes the code when it matches.
  def verify(candidate)
    return false unless usable?

    if ActiveSupport::SecurityUtils.secure_compare(code_digest, self.class.digest(candidate))
      consume!
      true
    else
      increment!(:attempts)
      false
    end
  end

  def consume!
    update!(consumed_at: Time.current)
  end

  def magic_link_token
    signed_id(expires_in: TTL, purpose: :magic_link)
  end
end
