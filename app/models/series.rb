# A recurring event brand, e.g. "Clinelympic Games". Optionally served on its
# own custom domain (clinelympics.com).
class Series < ApplicationRecord
  include Sluggable
  include Themeable

  has_prefixed_id :ser

  belongs_to :default_alias_pool, class_name: "AliasPool", optional: true
  has_many :events, -> { order(starts_at: :desc, created_at: :desc) }, dependent: :restrict_with_error, inverse_of: :series
  has_many :memberships, as: :resource, dependent: :delete_all
  has_many :alias_pools, as: :owner, dependent: :nullify

  has_rich_text :description
  has_one_attached :logo
  has_one_attached :hero

  normalizes :custom_domain, with: ->(domain) { domain.to_s.strip.downcase.delete_prefix("www.").presence }

  validates :name, presence: true, length: { maximum: 120 }
  validates :tagline, length: { maximum: 200 }
  validates :custom_domain, uniqueness: true, allow_nil: true,
    format: { with: /\A(?!-)[a-z0-9-]+(\.[a-z0-9-]+)+\z/, message: "must be a hostname like clinelympics.com" }

  def self.for_host(host)
    domain = host.to_s.downcase.delete_prefix("www.")
    find_by(custom_domain: domain) if domain.present?
  end

  def public_events
    events.publicly_visible
  end

  def latest_event
    public_events.first
  end
end
