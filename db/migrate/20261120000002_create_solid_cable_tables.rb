# Solid Queue/Cable tables live in the primary database (single PlanetScale DB).
# Third-party engine tables keep their own bigint IDs; see docs/MIGRATION_PLAN.md section 6.1.
class CreateSolidCableTables < ActiveRecord::Migration[8.1]
  def change
    create_table "solid_cable_messages" do |t|
      t.binary "channel", limit: 1024, null: false
      t.binary "payload", limit: 536870912, null: false
      t.datetime "created_at", null: false
      t.integer "channel_hash", limit: 8, null: false
      t.index [ "channel_hash" ], name: "index_solid_cable_messages_on_channel_hash"
      t.index [ "created_at" ], name: "index_solid_cable_messages_on_created_at"
    end
  end
end
