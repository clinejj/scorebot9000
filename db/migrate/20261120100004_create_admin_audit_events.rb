class CreateAdminAuditEvents < ActiveRecord::Migration[8.1]
  def change
    create_table :admin_audit_events, id: :uuid do |t|
      t.references :user, foreign_key: { on_delete: :nullify }, type: :uuid
      t.string :action, null: false
      t.string :subject
      t.jsonb :metadata, null: false, default: {}
      t.datetime :created_at, null: false
    end
    add_index :admin_audit_events, :created_at
  end
end
