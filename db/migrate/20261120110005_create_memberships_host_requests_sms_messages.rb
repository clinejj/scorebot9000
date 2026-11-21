class CreateMembershipsHostRequestsSmsMessages < ActiveRecord::Migration[8.1]
  def change
    create_table :memberships, id: :uuid do |t|
      t.references :user, null: false, foreign_key: { on_delete: :cascade }, type: :uuid
      t.references :resource, polymorphic: true, null: false, type: :uuid
      t.string :role, null: false
      t.timestamps
    end
    add_index :memberships, [ :user_id, :resource_type, :resource_id ], unique: true, name: "index_memberships_uniqueness"
    add_check_constraint :memberships, "role IN ('owner', 'organizer', 'scorekeeper')", name: "memberships_role_valid"
    add_check_constraint :memberships, "resource_type IN ('Series', 'Event')", name: "memberships_resource_type_valid"

    create_table :host_requests, id: :uuid do |t|
      t.references :user, null: false, foreign_key: { on_delete: :cascade }, type: :uuid
      t.text :message
      t.string :status, null: false, default: "pending"
      t.references :reviewed_by_user, foreign_key: { to_table: :users, on_delete: :nullify }, type: :uuid
      t.datetime :reviewed_at
      t.timestamps
    end
    add_check_constraint :host_requests, "status IN ('pending', 'approved', 'declined')", name: "host_requests_status_valid"

    create_table :sms_messages, id: :uuid do |t|
      t.string :direction, null: false
      t.string :twilio_sid
      t.string :from_number # encrypted deterministically
      t.string :to_number   # encrypted deterministically
      t.text :body
      t.references :user, foreign_key: { on_delete: :nullify }, type: :uuid
      t.references :event, foreign_key: { on_delete: :nullify }, type: :uuid
      t.references :reply_to, foreign_key: { to_table: :sms_messages, on_delete: :nullify }, type: :uuid
      t.string :command
      t.string :status
      t.string :error
      t.boolean :legacy, null: false, default: false
      t.boolean :simulated, null: false, default: false
      t.timestamps
    end
    add_index :sms_messages, :twilio_sid, unique: true
    add_index :sms_messages, :created_at
    add_check_constraint :sms_messages, "direction IN ('inbound', 'outbound')", name: "sms_messages_direction_valid"
  end
end
