module Maintenance
  module Users
    # Merges a duplicate account into another, by prefixed ID (usr_...).
    class MergeTask < MaintenanceTasks::Task
      no_collection

      attribute :keep_user_id, :string
      attribute :duplicate_user_id, :string
      validates :keep_user_id, :duplicate_user_id, presence: true

      def process
        keep = ::User.find(keep_user_id)
        duplicate = ::User.find(duplicate_user_id)
        ::Users::Merge.call(keep: keep, duplicate: duplicate)
      end
    end
  end
end
