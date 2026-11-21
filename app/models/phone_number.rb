# Phone number normalization. Everything is stored and compared as E.164
# ("+19097267311"); Phonelib assumes US numbers when no country code is given.
module PhoneNumber
  module_function

  # Numbers without a leading "+" must be valid North American (+1) numbers;
  # otherwise Phonelib may reinterpret e.g. "5551234567" as a Brazilian number.
  def normalize(input)
    return nil if input.blank?

    raw = input.to_s.strip
    phone = Phonelib.parse(raw)
    return nil unless phone.valid?
    return nil if !raw.start_with?("+") && !phone.e164.start_with?("+1")

    phone.e164
  end

  def valid?(input)
    normalize(input).present?
  end

  def looks_like_phone?(input)
    input.to_s.gsub(/[\s().+-]/, "").match?(/\A\d{7,15}\z/)
  end

  # "+19097267311" -> "(•••) •••-7311"
  def mask(e164)
    return nil if e164.blank?

    "(•••) •••-#{e164.to_s[-4..]}"
  end

  def display(e164)
    return nil if e164.blank?

    phone = Phonelib.parse(e164)
    phone.country == "US" ? phone.national : phone.international
  end
end
