class CreateGamesTeamsParticipants < ActiveRecord::Migration[8.1]
  def change
    create_table :games, id: :uuid do |t|
      t.references :event, null: false, foreign_key: { on_delete: :cascade }, type: :uuid
      t.integer :position, null: false
      t.string :name, null: false
      t.datetime :scheduled_at
      t.string :direction, null: false, default: "higher_better"
      t.string :score_format, null: false, default: "integer"
      t.string :participation, null: false, default: "individual"
      t.string :team_aggregation, null: false, default: "sum"
      t.integer :team_aggregation_n
      t.string :attempt_policy, null: false, default: "latest"
      t.decimal :weight, precision: 6, scale: 3, null: false, default: 1
      t.string :status, null: false, default: "open"
      t.integer :legacy_game_id
      t.timestamps
    end
    add_index :games, [ :event_id, :position ], unique: true
    add_check_constraint :games, "position > 0", name: "games_position_positive"
    add_check_constraint :games, "direction IN ('higher_better', 'lower_better')", name: "games_direction_valid"
    add_check_constraint :games, "score_format IN ('integer', 'decimal', 'time', 'placement')", name: "games_score_format_valid"
    add_check_constraint :games, "participation IN ('individual', 'team')", name: "games_participation_valid"
    add_check_constraint :games, "team_aggregation IN ('sum', 'average', 'best', 'top_n_sum', 'median')", name: "games_team_aggregation_valid"
    add_check_constraint :games, "attempt_policy IN ('latest', 'best', 'average')", name: "games_attempt_policy_valid"
    add_check_constraint :games, "status IN ('upcoming', 'open', 'locked', 'final')", name: "games_status_valid"
    add_check_constraint :games, "weight >= 0", name: "games_weight_non_negative"

    create_table :teams, id: :uuid do |t|
      t.references :event, null: false, foreign_key: { on_delete: :cascade }, type: :uuid
      t.string :name, null: false
      t.string :color
      t.string :emoji
      t.timestamps
    end
    add_index :teams, "event_id, lower(name)", unique: true, name: "index_teams_on_event_and_lower_name"

    create_table :participants, id: :uuid do |t|
      t.references :event, null: false, foreign_key: { on_delete: :cascade }, type: :uuid
      t.references :user, null: false, foreign_key: { on_delete: :cascade }, type: :uuid
      t.references :team, foreign_key: { on_delete: :nullify }, type: :uuid
      t.string :alias_name, null: false
      t.string :alias_source, null: false, default: "random"
      t.string :registered_via, null: false, default: "web"
      t.timestamps
    end
    add_index :participants, [ :event_id, :user_id ], unique: true
    add_index :participants, "event_id, lower(alias_name)", unique: true, name: "index_participants_on_event_and_lower_alias"
    add_check_constraint :participants, "alias_source IN ('random', 'chosen', 'real_name', 'import')", name: "participants_alias_source_valid"
    add_check_constraint :participants, "registered_via IN ('sms', 'web', 'organizer', 'import')", name: "participants_registered_via_valid"
  end
end
