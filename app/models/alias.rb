class Alias < ApplicationRecord
  belongs_to :alias_pool

  normalizes :name, with: ->(name) { name.squish }
  validates :name, presence: true, length: { maximum: 60 },
    uniqueness: { scope: :alias_pool_id, case_sensitive: false }
end
