class CreateUsers < ActiveRecord::Migration[8.1]
  def change
    create_table :users, id: :uuid do |t|
      t.string :name
      # email and phone are encrypted deterministically (still uniquely
      # indexable and queryable); see User.
      t.string :email
      t.string :phone
      t.string :pending_email
      t.datetime :email_verified_at
      t.datetime :phone_verified_at
      t.boolean :platform_admin, null: false, default: false
      t.string :legacy_admin_nickname
      t.timestamps
    end
    add_index :users, :email, unique: true
    add_index :users, :phone, unique: true
    add_index :users, :pending_email
    add_check_constraint :users, "email IS NOT NULL OR phone IS NOT NULL OR pending_email IS NOT NULL", name: "users_have_contact"
  end
end
