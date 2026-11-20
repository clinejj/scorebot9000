class CreateScoringTables < ActiveRecord::Migration[8.1]
  def change
    # Append-only: corrections void the old entry and add a new one.
    create_table :score_entries, id: :uuid do |t|
      t.references :game, null: false, foreign_key: { on_delete: :cascade }, type: :uuid
      t.references :participant, foreign_key: { on_delete: :cascade }, type: :uuid
      t.references :team, foreign_key: { on_delete: :cascade }, type: :uuid
      t.decimal :value, precision: 14, scale: 3, null: false
      t.string :raw_input
      t.string :source, null: false, default: "web"
      t.string :note
      t.references :submitted_by_user, foreign_key: { to_table: :users, on_delete: :nullify }, type: :uuid
      t.datetime :voided_at
      t.references :voided_by_user, foreign_key: { to_table: :users, on_delete: :nullify }, type: :uuid
      t.timestamps
    end
    add_index :score_entries, [ :game_id, :participant_id, :created_at ], where: "voided_at IS NULL", name: "index_score_entries_active_by_participant"
    add_index :score_entries, [ :game_id, :team_id, :created_at ], where: "voided_at IS NULL", name: "index_score_entries_active_by_team"
    add_check_constraint :score_entries, "num_nonnulls(participant_id, team_id) = 1", name: "score_entries_one_competitor"
    add_check_constraint :score_entries, "source IN ('sms', 'web', 'organizer', 'import', 'reconciliation')", name: "score_entries_source_valid"

    create_table :adjustments, id: :uuid do |t|
      t.references :event, null: false, foreign_key: { on_delete: :cascade }, type: :uuid
      t.references :participant, foreign_key: { on_delete: :cascade }, type: :uuid
      t.references :team, foreign_key: { on_delete: :cascade }, type: :uuid
      t.decimal :points, precision: 10, scale: 3, null: false
      t.string :reason, null: false
      t.references :created_by_user, foreign_key: { to_table: :users, on_delete: :nullify }, type: :uuid
      t.timestamps
    end
    add_check_constraint :adjustments, "num_nonnulls(participant_id, team_id) = 1", name: "adjustments_one_competitor"

    create_table :result_snapshots, id: :uuid do |t|
      t.references :event, null: false, foreign_key: { on_delete: :cascade }, type: :uuid
      t.datetime :computed_at, null: false
      t.jsonb :scoring_config, null: false, default: {}
      t.jsonb :standings, null: false, default: []
      t.jsonb :game_results, null: false, default: []
      t.boolean :official, null: false, default: false
      t.string :source, null: false, default: "computed"
      t.timestamps
    end
    add_index :result_snapshots, :event_id, unique: true, where: "official", name: "index_result_snapshots_one_official_per_event"
    add_check_constraint :result_snapshots, "source IN ('computed', 'legacy_capture')", name: "result_snapshots_source_valid"
  end
end
