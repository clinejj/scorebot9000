# Assigns a Ruby-minted UUIDv7 primary key before insert. Included in
# ApplicationRecord and in the Active Storage / Action Text base records (see
# config/initializers/uuid_v7.rb) so every uuid-keyed table gets v7 IDs.
#
# Bulk inserts (insert_all/upsert_all) skip callbacks: pass `id:` explicitly
# there, using Uuid7.generate.
module MintsUuidV7
  extend ActiveSupport::Concern

  included do
    before_create :assign_uuid_v7_primary_key
  end

  private
    def assign_uuid_v7_primary_key
      key = self.class.primary_key
      return unless key && self.class.columns_hash[key]&.type == :uuid

      self[key] ||= Uuid7.generate
    end
end
