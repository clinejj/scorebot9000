# Encodes and decodes TypeIDs (https://github.com/jetify-com/typeid):
# a type prefix plus a 128-bit UUID written as 26 Crockford base32 characters,
# e.g. "usr_01h455vb4pex5vsknk084sn02q".
#
# The suffix is a lossless re-encoding of the stored UUID, so a prefixed ID
# never needs its own column or lookup table.
module TypeId
  ALPHABET = "0123456789abcdefghjkmnpqrstvwxyz".freeze
  DECODE_MAP = ALPHABET.each_char.with_index.to_h.freeze
  PREFIX_FORMAT = /\A[a-z](?:[a-z_]{0,61}[a-z])?\z/
  SUFFIX_FORMAT = /\A[0-7][0-9a-hjkmnp-tv-z]{25}\z/
  UUID_FORMAT = /\A\h{8}-\h{4}-\h{4}-\h{4}-\h{12}\z/

  class InvalidError < ArgumentError; end

  module_function

  def encode(prefix, uuid)
    validate_prefix!(prefix)
    raise InvalidError, "not a UUID: #{uuid.inspect}" unless UUID_FORMAT.match?(uuid.to_s)

    int = uuid.delete("-").to_i(16)
    suffix = 25.downto(0).map { |i| ALPHABET[(int >> (5 * i)) & 31] }.join
    "#{prefix}_#{suffix}"
  end

  # Returns [prefix, uuid]. Raises InvalidError for malformed input.
  def decode(type_id)
    prefix, separator, suffix = type_id.to_s.rpartition("_")
    raise InvalidError, "missing prefix: #{type_id.inspect}" if separator.empty?
    raise InvalidError, "bad suffix: #{type_id.inspect}" unless SUFFIX_FORMAT.match?(suffix)
    validate_prefix!(prefix)

    int = suffix.each_char.reduce(0) { |acc, char| (acc << 5) | DECODE_MAP.fetch(char) }
    hex = int.to_s(16).rjust(32, "0")
    [ prefix, "#{hex[0, 8]}-#{hex[8, 4]}-#{hex[12, 4]}-#{hex[16, 4]}-#{hex[20, 12]}" ]
  end

  def valid?(type_id, prefix: nil)
    decoded_prefix, = decode(type_id)
    prefix.nil? || decoded_prefix == prefix.to_s
  rescue InvalidError
    false
  end

  def validate_prefix!(prefix)
    raise InvalidError, "bad prefix: #{prefix.inspect}" unless PREFIX_FORMAT.match?(prefix.to_s)
  end
end
