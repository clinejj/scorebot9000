# Parses and formats score values by a game's score_format. Values are stored
# as numeric(14,3): integers, decimals, times in seconds, or placements.
module ScoreValue
  MAX = BigDecimal("99999999999.999")

  module_function

  # Returns a BigDecimal, or nil when the input isn't valid for the format.
  def parse(input, format)
    raw = input.to_s.strip.delete(",")
    return nil if raw.empty?

    value =
      case format.to_s
      when "integer" then raw.match?(/\A-?\d+\z/) ? BigDecimal(raw) : nil
      when "decimal" then raw.match?(/\A-?(\d+(\.\d*)?|\.\d+)\z/) ? BigDecimal(raw).round(3) : nil
      when "time" then parse_time(raw)
      when "placement" then raw.sub(/(st|nd|rd|th)\z/i, "").then { |n| n.match?(/\A\d+\z/) && n.to_i.positive? ? BigDecimal(n) : nil }
      end
    value if value && value.abs <= MAX
  end

  # "1:23.45" -> 83.45, "1:02:03" -> 3723, "83.45" -> 83.45
  def parse_time(raw)
    return nil unless raw.match?(/\A\d+(:\d{1,2}){0,2}(\.\d+)?\z/)

    *bigger, seconds = raw.split(":")
    return nil if bigger.any? && seconds.to_f >= 60
    return nil if bigger.size == 2 && bigger.last.to_i >= 60

    total = bigger.reverse.each_with_index.sum { |part, index| part.to_i * (60**(index + 1)) }
    (BigDecimal(total) + BigDecimal(seconds)).round(3)
  end

  def format(value, format)
    return "" if value.nil?

    value = BigDecimal(value.to_s)
    case format.to_s
    when "integer" then value.to_i.to_s
    when "decimal" then trim(value)
    when "time" then format_time(value)
    when "placement" then value.to_i.ordinalize
    else trim(value)
    end
  end

  def format_time(seconds)
    whole = seconds.floor
    fraction = seconds - whole
    hours, remainder = whole.divmod(3600)
    minutes, secs = remainder.divmod(60)
    secs_text = trim(BigDecimal(secs) + fraction)
    secs_text = "0#{secs_text}" if (hours.positive? || minutes.positive?) && secs < 10
    if hours.positive?
      "#{hours}:#{minutes.to_s.rjust(2, "0")}:#{secs_text}"
    elsif minutes.positive?
      "#{minutes}:#{secs_text}"
    else
      secs_text
    end
  end

  def trim(value)
    text = value.to_s("F")
    text = text.sub(/\.?0+\z/, "") if text.include?(".")
    text
  end
end
