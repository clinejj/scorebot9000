# URL slugs for public pages (/s/clinelympics, /e/clinelympics-2021).
module Sluggable
  extend ActiveSupport::Concern

  FORMAT = /\A[a-z0-9]+(?:-[a-z0-9]+)*\z/
  RESERVED = %w[
    admin manage api session sessions sign_in sign-in sign-out me account new edit
    s e u privacy sms-terms terms up twilio assets rails cable host hosting about help
  ].freeze

  included do
    before_validation :assign_slug, if: -> { slug.blank? }
    normalizes :slug, with: ->(slug) { slug.to_s.strip.downcase }
    validates :slug, presence: true, uniqueness: true, length: { maximum: 80 },
      format: { with: FORMAT, message: "can only contain lowercase letters, numbers and dashes" },
      exclusion: { in: RESERVED, message: "is reserved" }
  end

  def to_param
    slug_was.presence || slug
  end

  private
    def slug_source
      name
    end

    def assign_slug
      base = slug_source.to_s.parameterize.first(70).presence || self.class.model_name.singular
      base = "#{base}-1" if RESERVED.include?(base)
      candidate = base
      counter = 2
      while self.class.unscoped.where.not(id: id).exists?(slug: candidate)
        candidate = "#{base}-#{counter}"
        counter += 1
      end
      self.slug = candidate
    end
end
