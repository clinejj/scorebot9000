# One occurrence of a competition, e.g. "2021 Clinelympic Games".
class Event < ApplicationRecord
  include Sluggable
  include Themeable

  has_prefixed_id :evt

  # Live pages subscribe to the event's stream (turbo_stream_from @event) and
  # morph-refresh on any change. Games, teams, participants and scores touch
  # the event, so their changes refresh too (debounced by Turbo).
  broadcasts_refreshes_to ->(event) { event }

  STATUSES = %w[draft published live final archived].freeze

  enum :status, STATUSES.index_with(&:itself), validate: true
  enum :team_mode, { none: "none", self_registered: "self_registered", assigned: "assigned" }, prefix: :teams, validate: true
  enum :alias_mode, { random: "random", self_chosen: "self_chosen", real_name: "real_name" }, prefix: :aliases, validate: true

  belongs_to :series, optional: true
  belongs_to :alias_pool, optional: true
  belongs_to :created_by_user, class_name: "User", optional: true

  has_many :games, -> { order(:position) }, dependent: :destroy, inverse_of: :event
  has_many :teams, -> { order(Arel.sql("lower(teams.name)")) }, dependent: :destroy, inverse_of: :event
  has_many :participants, dependent: :destroy, inverse_of: :event
  has_many :score_entries, through: :games
  has_many :adjustments, dependent: :destroy
  has_many :result_snapshots, dependent: :destroy
  has_one :official_snapshot, -> { where(official: true) }, class_name: "ResultSnapshot", inverse_of: :event
  has_many :memberships, as: :resource, dependent: :delete_all
  has_many :sms_messages, dependent: :nullify

  has_rich_text :description
  has_rich_text :rules
  has_rich_text :schedule
  has_one_attached :hero

  scope :publicly_visible, -> { where(status: %w[published live final archived]) }
  scope :listed, -> { where(status: %w[published live final]) }
  scope :upcoming, -> { where(status: "published") }
  scope :recent_results, -> { where(status: "final").order(finalized_at: :desc) }

  normalizes :sms_code, with: ->(code) { code.to_s.upcase.gsub(/[^A-Z0-9]/, "").presence }

  before_validation :assign_sms_code, on: :create, if: -> { sms_code.blank? }

  validates :name, presence: true, length: { maximum: 120 }
  validates :edition_label, length: { maximum: 40 }
  validates :sms_code, uniqueness: true, allow_nil: true, length: { in: 3..12 }
  validates :time_zone, inclusion: { in: ->(_) { ActiveSupport::TimeZone::MAPPING.values.uniq + ActiveSupport::TimeZone.all.map { |zone| zone.tzinfo.name } } }
  validates :max_team_size, numericality: { only_integer: true, greater_than: 0 }, allow_nil: true
  validate :ends_after_start
  validate :scoring_config_valid

  def display_name
    name
  end

  def publicly_visible?
    !draft?
  end

  def finished?
    final? || archived?
  end

  def accepting_registrations?
    registration_open? && (published? || live?)
  end

  def uses_teams?
    !teams_none?
  end

  # Theme falls back to the series theme.
  def accent_color
    super || series&.accent_color
  end

  def effective_alias_pool
    alias_pool || series&.default_alias_pool || AliasPool.platform_default
  end

  def local_starts_at
    starts_at&.in_time_zone(time_zone)
  end

  # Membership-based role for a user: :owner, :organizer, :scorekeeper or nil.
  # Series memberships apply to every event in the series.
  def role_for(user)
    return nil unless user
    return :owner if user.platform_admin?

    roles = Membership.where(user: user)
      .where("(resource_type = 'Event' AND resource_id = :event) OR (resource_type = 'Series' AND resource_id = :series)", event: id, series: series_id)
      .pluck(:role)
    Membership.highest_role(roles)
  end

  def owners
    owner_ids = Membership.where(role: "owner")
      .where("(resource_type = 'Event' AND resource_id = :event) OR (resource_type = 'Series' AND resource_id = :series)", event: id, series: series_id)
      .select(:user_id)
    User.where(id: owner_ids)
  end

  # SMS scoring is flagged in per host (plan section 7.5): enabled when any
  # owner of the event (or its series) has the sms_scoring flag.
  def sms_scoring_enabled?
    owners.any? { |owner| Flipper.enabled?(:sms_scoring, owner) }
  end

  def scoring_config
    Scoring::Config.from(scoring, uses_teams: uses_teams?)
  end

  def standings
    Scoring::Standings.for(self)
  end

  def participant_for(user)
    participants.find_by(user: user) if user
  end

  private
    def assign_sms_code
      letters = name.to_s.gsub(/\d+/, "").upcase.gsub(/[^A-Z]/, "").first(5).presence || "EVENT"
      year = (edition_label.presence || starts_at&.year || Time.current.year).to_s[/\d{2}\z/]
      base = "#{letters}#{year}"
      candidate = base
      counter = 2
      while Event.where.not(id: id).exists?(sms_code: candidate)
        candidate = "#{base}#{counter}"
        counter += 1
      end
      self.sms_code = candidate
    end

    def scoring_config_valid
      scoring_config.errors.each { |message| errors.add(:scoring, message) }
    end

    def ends_after_start
      errors.add(:ends_at, "must be after the start") if starts_at && ends_at && ends_at < starts_at
    end
end
