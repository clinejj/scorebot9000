class CreateEvents < ActiveRecord::Migration[8.1]
  def change
    create_table :events, id: :uuid do |t|
      t.references :series, foreign_key: { on_delete: :restrict }, type: :uuid
      t.string :slug, null: false
      t.string :name, null: false
      t.string :edition_label
      t.datetime :starts_at
      t.datetime :ends_at
      t.string :time_zone, null: false, default: "America/Los_Angeles"
      t.string :location_text
      t.string :online_url
      t.string :status, null: false, default: "draft"
      t.boolean :registration_open, null: false, default: false
      t.string :sms_code
      t.string :team_mode, null: false, default: "self_registered"
      t.integer :max_team_size
      t.string :alias_mode, null: false, default: "random"
      t.boolean :allow_alias_override, null: false, default: true
      t.jsonb :scoring, null: false, default: {}
      t.references :alias_pool, foreign_key: { on_delete: :nullify }, type: :uuid
      t.jsonb :theme, null: false, default: {}
      t.datetime :finalized_at
      t.integer :legacy_event_id
      t.references :created_by_user, foreign_key: { to_table: :users, on_delete: :nullify }, type: :uuid
      t.timestamps
    end
    add_index :events, :slug, unique: true
    add_index :events, :sms_code, unique: true
    add_index :events, :legacy_event_id, unique: true
    add_index :events, :status
    add_check_constraint :events, "status IN ('draft', 'published', 'live', 'final', 'archived')", name: "events_status_valid"
    add_check_constraint :events, "team_mode IN ('none', 'self_registered', 'assigned')", name: "events_team_mode_valid"
    add_check_constraint :events, "alias_mode IN ('random', 'self_chosen', 'real_name')", name: "events_alias_mode_valid"
    add_check_constraint :events, "max_team_size IS NULL OR max_team_size > 0", name: "events_max_team_size_positive"

    add_reference :users, :sms_context_event, foreign_key: { to_table: :events, on_delete: :nullify }, type: :uuid
  end
end
