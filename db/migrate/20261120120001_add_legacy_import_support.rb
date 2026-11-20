class AddLegacyImportSupport < ActiveRecord::Migration[8.1]
  def change
    # Legacy players whose ID isn't a valid phone number (the old admin forms
    # and SMS simulator allowed free text) become placeholder users.
    add_column :users, :placeholder, :boolean, null: false, default: false
    add_column :users, :legacy_player_id, :string # encrypted deterministically
    add_index :users, :legacy_player_id, unique: true
    remove_check_constraint :users, "email IS NOT NULL OR phone IS NOT NULL OR pending_email IS NOT NULL", name: "users_have_contact"
    add_check_constraint :users, "email IS NOT NULL OR phone IS NOT NULL OR pending_email IS NOT NULL OR placeholder", name: "users_have_contact"

    create_table :legacy_imports, id: :uuid do |t|
      t.string :status, null: false, default: "uploaded"
      t.jsonb :report, null: false, default: {}
      t.references :created_by_user, foreign_key: { to_table: :users, on_delete: :nullify }, type: :uuid
      t.datetime :started_at
      t.datetime :finished_at
      t.timestamps
    end
    add_check_constraint :legacy_imports, "status IN ('uploaded', 'running', 'succeeded', 'failed')", name: "legacy_imports_status_valid"
  end
end
