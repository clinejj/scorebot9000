class CreateAliasPoolsAndSeries < ActiveRecord::Migration[8.1]
  def change
    create_table :alias_pools, id: :uuid do |t|
      t.string :name, null: false
      # nil owner = a platform-wide pool
      t.references :owner, polymorphic: true, type: :uuid
      t.timestamps
    end

    create_table :aliases, id: :uuid do |t|
      t.references :alias_pool, null: false, foreign_key: { on_delete: :cascade }, type: :uuid
      t.string :name, null: false
      t.timestamps
    end
    add_index :aliases, "alias_pool_id, lower(name)", unique: true, name: "index_aliases_on_pool_and_lower_name"

    create_table :series, id: :uuid do |t|
      t.string :slug, null: false
      t.string :name, null: false
      t.string :tagline
      t.jsonb :theme, null: false, default: {}
      t.string :custom_domain
      t.references :default_alias_pool, foreign_key: { to_table: :alias_pools, on_delete: :nullify }, type: :uuid
      t.timestamps
    end
    add_index :series, :slug, unique: true
    add_index :series, :custom_domain, unique: true
  end
end
