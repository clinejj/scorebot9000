module Maintenance
  module Aliases
    # Adds aliases from a CSV with a `name` column to a pool (created if it
    # doesn't exist). Leave owner_series_slug blank for a platform-wide pool.
    class ImportPoolTask < MaintenanceTasks::Task
      csv_collection

      attribute :pool_name, :string
      attribute :owner_series_slug, :string
      validates :pool_name, presence: true

      def process(row)
        pool.add_names(row["name"].to_s)
      end

      private
        def pool
          @pool ||= begin
            owner = Series.find_by!(slug: owner_series_slug) if owner_series_slug.present?
            AliasPool.find_or_create_by!(name: pool_name, owner: owner)
          end
        end
    end
  end
end
