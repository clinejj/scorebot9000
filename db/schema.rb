# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_11_20_120001) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "action_text_rich_texts", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name", null: false
    t.text "body"
    t.string "record_type", null: false
    t.uuid "record_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["record_type", "record_id", "name"], name: "index_action_text_rich_texts_uniqueness", unique: true
  end

  create_table "active_storage_attachments", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.uuid "record_id", null: false
    t.uuid "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "adjustments", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "event_id", null: false
    t.uuid "participant_id"
    t.uuid "team_id"
    t.decimal "points", precision: 10, scale: 3, null: false
    t.string "reason", null: false
    t.uuid "created_by_user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_by_user_id"], name: "index_adjustments_on_created_by_user_id"
    t.index ["event_id"], name: "index_adjustments_on_event_id"
    t.index ["participant_id"], name: "index_adjustments_on_participant_id"
    t.index ["team_id"], name: "index_adjustments_on_team_id"
    t.check_constraint "num_nonnulls(participant_id, team_id) = 1", name: "adjustments_one_competitor"
  end

  create_table "admin_audit_events", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "user_id"
    t.string "action", null: false
    t.string "subject"
    t.jsonb "metadata", default: {}, null: false
    t.datetime "created_at", null: false
    t.index ["created_at"], name: "index_admin_audit_events_on_created_at"
    t.index ["user_id"], name: "index_admin_audit_events_on_user_id"
  end

  create_table "alias_pools", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name", null: false
    t.string "owner_type"
    t.uuid "owner_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["owner_type", "owner_id"], name: "index_alias_pools_on_owner"
  end

  create_table "aliases", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "alias_pool_id", null: false
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index "alias_pool_id, lower((name)::text)", name: "index_aliases_on_pool_and_lower_name", unique: true
    t.index ["alias_pool_id"], name: "index_aliases_on_alias_pool_id"
  end

  create_table "blazer_audits", force: :cascade do |t|
    t.uuid "user_id"
    t.bigint "query_id"
    t.text "statement"
    t.string "data_source"
    t.datetime "created_at"
    t.index ["query_id"], name: "index_blazer_audits_on_query_id"
    t.index ["user_id"], name: "index_blazer_audits_on_user_id"
  end

  create_table "blazer_checks", force: :cascade do |t|
    t.uuid "creator_id"
    t.bigint "query_id"
    t.string "state"
    t.string "schedule"
    t.text "emails"
    t.text "slack_channels"
    t.string "check_type"
    t.text "message"
    t.datetime "last_run_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["creator_id"], name: "index_blazer_checks_on_creator_id"
    t.index ["query_id"], name: "index_blazer_checks_on_query_id"
  end

  create_table "blazer_dashboard_queries", force: :cascade do |t|
    t.bigint "dashboard_id"
    t.bigint "query_id"
    t.integer "position"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["dashboard_id"], name: "index_blazer_dashboard_queries_on_dashboard_id"
    t.index ["query_id"], name: "index_blazer_dashboard_queries_on_query_id"
  end

  create_table "blazer_dashboards", force: :cascade do |t|
    t.uuid "creator_id"
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["creator_id"], name: "index_blazer_dashboards_on_creator_id"
  end

  create_table "blazer_queries", force: :cascade do |t|
    t.uuid "creator_id"
    t.string "name"
    t.text "description"
    t.text "statement"
    t.string "data_source"
    t.string "status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["creator_id"], name: "index_blazer_queries_on_creator_id"
  end

  create_table "events", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "series_id"
    t.string "slug", null: false
    t.string "name", null: false
    t.string "edition_label"
    t.datetime "starts_at"
    t.datetime "ends_at"
    t.string "time_zone", default: "America/Los_Angeles", null: false
    t.string "location_text"
    t.string "online_url"
    t.string "status", default: "draft", null: false
    t.boolean "registration_open", default: false, null: false
    t.string "sms_code"
    t.string "team_mode", default: "self_registered", null: false
    t.integer "max_team_size"
    t.string "alias_mode", default: "random", null: false
    t.boolean "allow_alias_override", default: true, null: false
    t.jsonb "scoring", default: {}, null: false
    t.uuid "alias_pool_id"
    t.jsonb "theme", default: {}, null: false
    t.datetime "finalized_at"
    t.integer "legacy_event_id"
    t.uuid "created_by_user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["alias_pool_id"], name: "index_events_on_alias_pool_id"
    t.index ["created_by_user_id"], name: "index_events_on_created_by_user_id"
    t.index ["legacy_event_id"], name: "index_events_on_legacy_event_id", unique: true
    t.index ["series_id"], name: "index_events_on_series_id"
    t.index ["slug"], name: "index_events_on_slug", unique: true
    t.index ["sms_code"], name: "index_events_on_sms_code", unique: true
    t.index ["status"], name: "index_events_on_status"
    t.check_constraint "alias_mode::text = ANY (ARRAY['random'::character varying, 'self_chosen'::character varying, 'real_name'::character varying]::text[])", name: "events_alias_mode_valid"
    t.check_constraint "max_team_size IS NULL OR max_team_size > 0", name: "events_max_team_size_positive"
    t.check_constraint "status::text = ANY (ARRAY['draft'::character varying, 'published'::character varying, 'live'::character varying, 'final'::character varying, 'archived'::character varying]::text[])", name: "events_status_valid"
    t.check_constraint "team_mode::text = ANY (ARRAY['none'::character varying, 'self_registered'::character varying, 'assigned'::character varying]::text[])", name: "events_team_mode_valid"
  end

  create_table "flipper_features", force: :cascade do |t|
    t.string "key", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_flipper_features_on_key", unique: true
  end

  create_table "flipper_gates", force: :cascade do |t|
    t.string "feature_key", null: false
    t.string "key", null: false
    t.text "value"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["feature_key", "key", "value"], name: "index_flipper_gates_on_feature_key_and_key_and_value", unique: true
  end

  create_table "games", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "event_id", null: false
    t.integer "position", null: false
    t.string "name", null: false
    t.datetime "scheduled_at"
    t.string "direction", default: "higher_better", null: false
    t.string "score_format", default: "integer", null: false
    t.string "participation", default: "individual", null: false
    t.string "team_aggregation", default: "sum", null: false
    t.integer "team_aggregation_n"
    t.string "attempt_policy", default: "latest", null: false
    t.decimal "weight", precision: 6, scale: 3, default: "1.0", null: false
    t.string "status", default: "open", null: false
    t.integer "legacy_game_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["event_id", "position"], name: "index_games_on_event_id_and_position", unique: true
    t.index ["event_id"], name: "index_games_on_event_id"
    t.check_constraint "\"position\" > 0", name: "games_position_positive"
    t.check_constraint "attempt_policy::text = ANY (ARRAY['latest'::character varying, 'best'::character varying, 'average'::character varying]::text[])", name: "games_attempt_policy_valid"
    t.check_constraint "direction::text = ANY (ARRAY['higher_better'::character varying, 'lower_better'::character varying]::text[])", name: "games_direction_valid"
    t.check_constraint "participation::text = ANY (ARRAY['individual'::character varying, 'team'::character varying]::text[])", name: "games_participation_valid"
    t.check_constraint "score_format::text = ANY (ARRAY['integer'::character varying, 'decimal'::character varying, 'time'::character varying, 'placement'::character varying]::text[])", name: "games_score_format_valid"
    t.check_constraint "status::text = ANY (ARRAY['upcoming'::character varying, 'open'::character varying, 'locked'::character varying, 'final'::character varying]::text[])", name: "games_status_valid"
    t.check_constraint "team_aggregation::text = ANY (ARRAY['sum'::character varying, 'average'::character varying, 'best'::character varying, 'top_n_sum'::character varying, 'median'::character varying]::text[])", name: "games_team_aggregation_valid"
    t.check_constraint "weight >= 0::numeric", name: "games_weight_non_negative"
  end

  create_table "host_requests", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "user_id", null: false
    t.text "message"
    t.string "status", default: "pending", null: false
    t.uuid "reviewed_by_user_id"
    t.datetime "reviewed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["reviewed_by_user_id"], name: "index_host_requests_on_reviewed_by_user_id"
    t.index ["user_id"], name: "index_host_requests_on_user_id"
    t.check_constraint "status::text = ANY (ARRAY['pending'::character varying, 'approved'::character varying, 'declined'::character varying]::text[])", name: "host_requests_status_valid"
  end

  create_table "legacy_imports", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "status", default: "uploaded", null: false
    t.jsonb "report", default: {}, null: false
    t.uuid "created_by_user_id"
    t.datetime "started_at"
    t.datetime "finished_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_by_user_id"], name: "index_legacy_imports_on_created_by_user_id"
    t.check_constraint "status::text = ANY (ARRAY['uploaded'::character varying, 'running'::character varying, 'succeeded'::character varying, 'failed'::character varying]::text[])", name: "legacy_imports_status_valid"
  end

  create_table "maintenance_tasks_runs", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "task_name", null: false
    t.datetime "started_at"
    t.datetime "ended_at"
    t.float "time_running", default: 0.0, null: false
    t.bigint "tick_count", default: 0, null: false
    t.bigint "tick_total"
    t.string "job_id"
    t.string "cursor"
    t.string "status", default: "enqueued", null: false
    t.string "error_class"
    t.string "error_message"
    t.text "backtrace"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "arguments"
    t.integer "lock_version", default: 0, null: false
    t.text "metadata"
    t.boolean "cursor_is_json", default: false, null: false
    t.index ["task_name", "status", "created_at"], name: "index_maintenance_tasks_runs", order: { created_at: :desc }
  end

  create_table "memberships", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "user_id", null: false
    t.string "resource_type", null: false
    t.uuid "resource_id", null: false
    t.string "role", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["resource_type", "resource_id"], name: "index_memberships_on_resource"
    t.index ["user_id", "resource_type", "resource_id"], name: "index_memberships_uniqueness", unique: true
    t.index ["user_id"], name: "index_memberships_on_user_id"
    t.check_constraint "resource_type::text = ANY (ARRAY['Series'::character varying, 'Event'::character varying]::text[])", name: "memberships_resource_type_valid"
    t.check_constraint "role::text = ANY (ARRAY['owner'::character varying, 'organizer'::character varying, 'scorekeeper'::character varying]::text[])", name: "memberships_role_valid"
  end

  create_table "participants", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "event_id", null: false
    t.uuid "user_id", null: false
    t.uuid "team_id"
    t.string "alias_name", null: false
    t.string "alias_source", default: "random", null: false
    t.string "registered_via", default: "web", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index "event_id, lower((alias_name)::text)", name: "index_participants_on_event_and_lower_alias", unique: true
    t.index ["event_id", "user_id"], name: "index_participants_on_event_id_and_user_id", unique: true
    t.index ["event_id"], name: "index_participants_on_event_id"
    t.index ["team_id"], name: "index_participants_on_team_id"
    t.index ["user_id"], name: "index_participants_on_user_id"
    t.check_constraint "alias_source::text = ANY (ARRAY['random'::character varying, 'chosen'::character varying, 'real_name'::character varying, 'import'::character varying]::text[])", name: "participants_alias_source_valid"
    t.check_constraint "registered_via::text = ANY (ARRAY['sms'::character varying, 'web'::character varying, 'organizer'::character varying, 'import'::character varying]::text[])", name: "participants_registered_via_valid"
  end

  create_table "result_snapshots", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "event_id", null: false
    t.datetime "computed_at", null: false
    t.jsonb "scoring_config", default: {}, null: false
    t.jsonb "standings", default: [], null: false
    t.jsonb "game_results", default: [], null: false
    t.boolean "official", default: false, null: false
    t.string "source", default: "computed", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["event_id"], name: "index_result_snapshots_on_event_id"
    t.index ["event_id"], name: "index_result_snapshots_one_official_per_event", unique: true, where: "official"
    t.check_constraint "source::text = ANY (ARRAY['computed'::character varying, 'legacy_capture'::character varying]::text[])", name: "result_snapshots_source_valid"
  end

  create_table "score_entries", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "game_id", null: false
    t.uuid "participant_id"
    t.uuid "team_id"
    t.decimal "value", precision: 14, scale: 3, null: false
    t.string "raw_input"
    t.string "source", default: "web", null: false
    t.string "note"
    t.uuid "submitted_by_user_id"
    t.datetime "voided_at"
    t.uuid "voided_by_user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["game_id", "participant_id", "created_at"], name: "index_score_entries_active_by_participant", where: "(voided_at IS NULL)"
    t.index ["game_id", "team_id", "created_at"], name: "index_score_entries_active_by_team", where: "(voided_at IS NULL)"
    t.index ["game_id"], name: "index_score_entries_on_game_id"
    t.index ["participant_id"], name: "index_score_entries_on_participant_id"
    t.index ["submitted_by_user_id"], name: "index_score_entries_on_submitted_by_user_id"
    t.index ["team_id"], name: "index_score_entries_on_team_id"
    t.index ["voided_by_user_id"], name: "index_score_entries_on_voided_by_user_id"
    t.check_constraint "num_nonnulls(participant_id, team_id) = 1", name: "score_entries_one_competitor"
    t.check_constraint "source::text = ANY (ARRAY['sms'::character varying, 'web'::character varying, 'organizer'::character varying, 'import'::character varying, 'reconciliation'::character varying]::text[])", name: "score_entries_source_valid"
  end

  create_table "series", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "slug", null: false
    t.string "name", null: false
    t.string "tagline"
    t.jsonb "theme", default: {}, null: false
    t.string "custom_domain"
    t.uuid "default_alias_pool_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["custom_domain"], name: "index_series_on_custom_domain", unique: true
    t.index ["default_alias_pool_id"], name: "index_series_on_default_alias_pool_id"
    t.index ["slug"], name: "index_series_on_slug", unique: true
  end

  create_table "sessions", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "user_id", null: false
    t.string "ip_address"
    t.string "user_agent"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "sign_in_codes", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "email", null: false
    t.string "code_digest", null: false
    t.datetime "expires_at", null: false
    t.integer "attempts", default: 0, null: false
    t.datetime "consumed_at"
    t.string "ip_address"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email", "created_at"], name: "index_sign_in_codes_on_email_and_created_at"
  end

  create_table "sms_messages", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "direction", null: false
    t.string "twilio_sid"
    t.string "from_number"
    t.string "to_number"
    t.text "body"
    t.uuid "user_id"
    t.uuid "event_id"
    t.uuid "reply_to_id"
    t.string "command"
    t.string "status"
    t.string "error"
    t.boolean "legacy", default: false, null: false
    t.boolean "simulated", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_sms_messages_on_created_at"
    t.index ["event_id"], name: "index_sms_messages_on_event_id"
    t.index ["reply_to_id"], name: "index_sms_messages_on_reply_to_id"
    t.index ["twilio_sid"], name: "index_sms_messages_on_twilio_sid", unique: true
    t.index ["user_id"], name: "index_sms_messages_on_user_id"
    t.check_constraint "direction::text = ANY (ARRAY['inbound'::character varying, 'outbound'::character varying]::text[])", name: "sms_messages_direction_valid"
  end

  create_table "solid_cable_messages", force: :cascade do |t|
    t.binary "channel", null: false
    t.binary "payload", null: false
    t.datetime "created_at", null: false
    t.bigint "channel_hash", null: false
    t.index ["channel_hash"], name: "index_solid_cable_messages_on_channel_hash"
    t.index ["created_at"], name: "index_solid_cable_messages_on_created_at"
  end

  create_table "solid_queue_batch_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.bigint "batch_id", null: false
    t.datetime "created_at", null: false
    t.index ["batch_id"], name: "index_solid_queue_batch_executions_on_batch_id"
    t.index ["job_id"], name: "index_solid_queue_batch_executions_on_job_id", unique: true
  end

  create_table "solid_queue_batches", force: :cascade do |t|
    t.string "active_job_batch_id"
    t.string "description"
    t.text "on_finish"
    t.text "on_success"
    t.text "on_failure"
    t.text "metadata"
    t.integer "total_jobs", default: 0, null: false
    t.integer "completed_jobs", default: 0, null: false
    t.integer "failed_jobs", default: 0, null: false
    t.datetime "enqueued_at"
    t.datetime "finished_at"
    t.datetime "failed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["active_job_batch_id"], name: "index_solid_queue_batches_on_active_job_batch_id", unique: true
    t.index ["finished_at"], name: "index_solid_queue_batches_on_finished_at"
  end

  create_table "solid_queue_blocked_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.string "queue_name", null: false
    t.integer "priority", default: 0, null: false
    t.string "concurrency_key", null: false
    t.datetime "expires_at", null: false
    t.datetime "created_at", null: false
    t.index ["concurrency_key", "priority", "job_id"], name: "index_solid_queue_blocked_executions_for_release"
    t.index ["expires_at", "concurrency_key"], name: "index_solid_queue_blocked_executions_for_maintenance"
    t.index ["job_id"], name: "index_solid_queue_blocked_executions_on_job_id", unique: true
  end

  create_table "solid_queue_claimed_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.bigint "process_id"
    t.datetime "created_at", null: false
    t.index ["job_id"], name: "index_solid_queue_claimed_executions_on_job_id", unique: true
    t.index ["process_id", "job_id"], name: "index_solid_queue_claimed_executions_on_process_id_and_job_id"
  end

  create_table "solid_queue_failed_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.text "error"
    t.datetime "created_at", null: false
    t.index ["job_id"], name: "index_solid_queue_failed_executions_on_job_id", unique: true
  end

  create_table "solid_queue_jobs", force: :cascade do |t|
    t.string "queue_name", null: false
    t.string "class_name", null: false
    t.text "arguments"
    t.integer "priority", default: 0, null: false
    t.string "active_job_id"
    t.datetime "scheduled_at"
    t.datetime "finished_at"
    t.string "concurrency_key"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "batch_id"
    t.index ["active_job_id"], name: "index_solid_queue_jobs_on_active_job_id"
    t.index ["batch_id"], name: "index_solid_queue_jobs_on_batch_id"
    t.index ["class_name"], name: "index_solid_queue_jobs_on_class_name"
    t.index ["finished_at"], name: "index_solid_queue_jobs_on_finished_at"
    t.index ["queue_name", "finished_at"], name: "index_solid_queue_jobs_for_filtering"
    t.index ["scheduled_at", "finished_at"], name: "index_solid_queue_jobs_for_alerting"
  end

  create_table "solid_queue_pauses", force: :cascade do |t|
    t.string "queue_name", null: false
    t.datetime "created_at", null: false
    t.index ["queue_name"], name: "index_solid_queue_pauses_on_queue_name", unique: true
  end

  create_table "solid_queue_processes", force: :cascade do |t|
    t.string "kind", null: false
    t.datetime "last_heartbeat_at", null: false
    t.bigint "supervisor_id"
    t.integer "pid", null: false
    t.string "hostname"
    t.text "metadata"
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.index ["last_heartbeat_at"], name: "index_solid_queue_processes_on_last_heartbeat_at"
    t.index ["name", "supervisor_id"], name: "index_solid_queue_processes_on_name_and_supervisor_id", unique: true
    t.index ["supervisor_id"], name: "index_solid_queue_processes_on_supervisor_id"
  end

  create_table "solid_queue_ready_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.string "queue_name", null: false
    t.integer "priority", default: 0, null: false
    t.datetime "created_at", null: false
    t.index ["job_id"], name: "index_solid_queue_ready_executions_on_job_id", unique: true
    t.index ["priority", "job_id"], name: "index_solid_queue_poll_all"
    t.index ["queue_name", "priority", "job_id"], name: "index_solid_queue_poll_by_queue"
  end

  create_table "solid_queue_recurring_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.string "task_key", null: false
    t.datetime "run_at", null: false
    t.datetime "created_at", null: false
    t.index ["job_id"], name: "index_solid_queue_recurring_executions_on_job_id", unique: true
    t.index ["task_key", "run_at"], name: "index_solid_queue_recurring_executions_on_task_key_and_run_at", unique: true
  end

  create_table "solid_queue_recurring_tasks", force: :cascade do |t|
    t.string "key", null: false
    t.string "schedule", null: false
    t.string "command", limit: 2048
    t.string "class_name"
    t.text "arguments"
    t.string "queue_name"
    t.integer "priority", default: 0
    t.boolean "static", default: true, null: false
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_solid_queue_recurring_tasks_on_key", unique: true
    t.index ["static"], name: "index_solid_queue_recurring_tasks_on_static"
  end

  create_table "solid_queue_scheduled_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.string "queue_name", null: false
    t.integer "priority", default: 0, null: false
    t.datetime "scheduled_at", null: false
    t.datetime "created_at", null: false
    t.index ["job_id"], name: "index_solid_queue_scheduled_executions_on_job_id", unique: true
    t.index ["scheduled_at", "priority", "job_id"], name: "index_solid_queue_dispatch_all"
  end

  create_table "solid_queue_semaphores", force: :cascade do |t|
    t.string "key", null: false
    t.integer "value", default: 1, null: false
    t.datetime "expires_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["expires_at"], name: "index_solid_queue_semaphores_on_expires_at"
    t.index ["key", "value"], name: "index_solid_queue_semaphores_on_key_and_value"
    t.index ["key"], name: "index_solid_queue_semaphores_on_key", unique: true
  end

  create_table "teams", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "event_id", null: false
    t.string "name", null: false
    t.string "color"
    t.string "emoji"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index "event_id, lower((name)::text)", name: "index_teams_on_event_and_lower_name", unique: true
    t.index ["event_id"], name: "index_teams_on_event_id"
  end

  create_table "users", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name"
    t.string "email"
    t.string "phone"
    t.string "pending_email"
    t.datetime "email_verified_at"
    t.datetime "phone_verified_at"
    t.boolean "platform_admin", default: false, null: false
    t.string "legacy_admin_nickname"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.uuid "sms_context_event_id"
    t.boolean "placeholder", default: false, null: false
    t.string "legacy_player_id"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["legacy_player_id"], name: "index_users_on_legacy_player_id", unique: true
    t.index ["pending_email"], name: "index_users_on_pending_email"
    t.index ["phone"], name: "index_users_on_phone", unique: true
    t.index ["sms_context_event_id"], name: "index_users_on_sms_context_event_id"
    t.check_constraint "email IS NOT NULL OR phone IS NOT NULL OR pending_email IS NOT NULL OR placeholder", name: "users_have_contact"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "adjustments", "events", on_delete: :cascade
  add_foreign_key "adjustments", "participants", on_delete: :cascade
  add_foreign_key "adjustments", "teams", on_delete: :cascade
  add_foreign_key "adjustments", "users", column: "created_by_user_id", on_delete: :nullify
  add_foreign_key "admin_audit_events", "users", on_delete: :nullify
  add_foreign_key "aliases", "alias_pools", on_delete: :cascade
  add_foreign_key "events", "alias_pools", on_delete: :nullify
  add_foreign_key "events", "series", on_delete: :restrict
  add_foreign_key "events", "users", column: "created_by_user_id", on_delete: :nullify
  add_foreign_key "games", "events", on_delete: :cascade
  add_foreign_key "host_requests", "users", column: "reviewed_by_user_id", on_delete: :nullify
  add_foreign_key "host_requests", "users", on_delete: :cascade
  add_foreign_key "legacy_imports", "users", column: "created_by_user_id", on_delete: :nullify
  add_foreign_key "memberships", "users", on_delete: :cascade
  add_foreign_key "participants", "events", on_delete: :cascade
  add_foreign_key "participants", "teams", on_delete: :nullify
  add_foreign_key "participants", "users", on_delete: :cascade
  add_foreign_key "result_snapshots", "events", on_delete: :cascade
  add_foreign_key "score_entries", "games", on_delete: :cascade
  add_foreign_key "score_entries", "participants", on_delete: :cascade
  add_foreign_key "score_entries", "teams", on_delete: :cascade
  add_foreign_key "score_entries", "users", column: "submitted_by_user_id", on_delete: :nullify
  add_foreign_key "score_entries", "users", column: "voided_by_user_id", on_delete: :nullify
  add_foreign_key "series", "alias_pools", column: "default_alias_pool_id", on_delete: :nullify
  add_foreign_key "sessions", "users", on_delete: :cascade
  add_foreign_key "sms_messages", "events", on_delete: :nullify
  add_foreign_key "sms_messages", "sms_messages", column: "reply_to_id", on_delete: :nullify
  add_foreign_key "sms_messages", "users", on_delete: :nullify
  add_foreign_key "solid_queue_batch_executions", "solid_queue_batches", column: "batch_id", on_delete: :cascade
  add_foreign_key "solid_queue_batch_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_blocked_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_claimed_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_failed_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_ready_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_recurring_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_scheduled_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "teams", "events", on_delete: :cascade
  add_foreign_key "users", "events", column: "sms_context_event_id", on_delete: :nullify
end
