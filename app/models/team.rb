class Team < ApplicationRecord
  has_prefixed_id :team

  COLORS = %w[#dc2626 #ea580c #ca8a04 #16a34a #0891b2 #2563eb #7c3aed #db2777 #475569 #65a30d #0d9488 #9333ea].freeze

  belongs_to :event, touch: true
  has_many :participants, dependent: :nullify
  has_many :score_entries, dependent: :destroy
  has_many :adjustments, dependent: :destroy

  normalizes :name, with: ->(name) { name.squish }

  before_validation :assign_color, on: :create

  validates :name, presence: true, length: { maximum: 60 }, uniqueness: { scope: :event_id, case_sensitive: false }
  validates :color, format: { with: Themeable::HEX_COLOR }, allow_nil: true
  validates :emoji, length: { maximum: 8 }

  def self.find_by_name(name)
    find_by("lower(name) = ?", name.to_s.squish.downcase)
  end

  def full?
    event.max_team_size.present? && participants.count >= event.max_team_size
  end

  def display_name
    [ emoji.presence, name ].compact.join(" ")
  end

  private
    def assign_color
      return if color.present? || event.nil?

      used = event.teams.where.not(id: id).pluck(:color)
      self.color = (COLORS - used).first || COLORS[event.teams.count % COLORS.size]
    end
end
