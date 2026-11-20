# Parses the single "Email or mobile number" sign-in field.
Identifier = Data.define(:kind, :value) do
  def self.parse(input)
    raw = input.to_s.strip
    return nil if raw.blank?

    if raw.include?("@")
      email = raw.downcase
      new(kind: :email, value: email) if email.match?(URI::MailTo::EMAIL_REGEXP)
    elsif PhoneNumber.looks_like_phone?(raw)
      phone = PhoneNumber.normalize(raw)
      new(kind: :phone, value: phone) if phone
    end
  end

  def email? = kind == :email
  def phone? = kind == :phone
end
