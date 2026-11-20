# A pool of random player aliases ("Usain Bolt", "The Great Gatsby", ...).
# Pools belong to a series (or nobody, for the platform default).
class AliasPool < ApplicationRecord
  has_prefixed_id :apool

  PLATFORM_DEFAULT_NAME = "Scorebot classics".freeze

  belongs_to :owner, polymorphic: true, optional: true
  has_many :aliases, -> { order(:name) }, dependent: :delete_all, inverse_of: :alias_pool

  validates :name, presence: true, length: { maximum: 80 }

  def self.platform_default
    find_by(owner_id: nil, name: PLATFORM_DEFAULT_NAME)
  end

  # Adds names (one per line), skipping duplicates. Returns the number added.
  def add_names(text)
    names = text.to_s.lines.map(&:squish).compact_blank.uniq { |name| name.downcase }
    existing = aliases.pluck(:name).map(&:downcase).to_set
    rows = names.reject { |name| existing.include?(name.downcase) }.map do |name|
      { id: Uuid7.generate, alias_pool_id: id, name: name.first(60), created_at: Time.current, updated_at: Time.current }
    end
    Alias.insert_all(rows, unique_by: :index_aliases_on_pool_and_lower_name) if rows.any?
    rows.size
  end
end
