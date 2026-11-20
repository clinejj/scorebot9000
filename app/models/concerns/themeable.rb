# Per-series/event theme stored as JSON, e.g. { "accent" => "#b91c1c" }.
module Themeable
  extend ActiveSupport::Concern

  HEX_COLOR = /\A#\h{6}\z/

  included do
    validate :theme_colors_are_hex
  end

  def accent_color
    theme["accent"].presence
  end

  def accent_color=(value)
    self.theme = theme.merge("accent" => value.presence).compact
  end

  # Text color that stays readable on the accent background.
  def accent_ink_color
    hex = accent_color or return nil
    r, g, b = hex.delete("#").scan(/../).map { |c| c.to_i(16) }
    luminance = (0.299 * r + 0.587 * g + 0.114 * b) / 255
    luminance > 0.6 ? "#1c1917" : "#ffffff"
  end

  private
    def theme_colors_are_hex
      theme.slice("accent").each do |key, value|
        errors.add(:theme, "#{key} must be a hex color like #b91c1c") unless value.to_s.match?(HEX_COLOR)
      end
    end
end
