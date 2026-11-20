class CreateSignInCodes < ActiveRecord::Migration[8.1]
  def change
    create_table :sign_in_codes, id: :uuid do |t|
      t.string :email, null: false # encrypted deterministically
      t.string :code_digest, null: false
      t.datetime :expires_at, null: false
      t.integer :attempts, null: false, default: 0
      t.datetime :consumed_at
      t.string :ip_address
      t.timestamps
    end
    add_index :sign_in_codes, [ :email, :created_at ]
  end
end
