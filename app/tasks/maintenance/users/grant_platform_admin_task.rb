module Maintenance
  module Users
    # Grants (or revokes) platform admin. The first admin is bootstrapped with
    # `bin/rails users:grant_admin`; use this for everyone after that.
    class GrantPlatformAdminTask < MaintenanceTasks::Task
      no_collection

      attribute :email, :string
      attribute :revoke, :boolean, default: false
      validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }

      def process
        user = ::User.find_by(email: email) || ::User.create!(email: email)
        if revoke
          user.revoke_platform_admin!
          AdminAuditEvent.record!("users.revoke_admin", subject: user.public_id, user: nil, via: "maintenance_task")
        else
          user.grant_platform_admin!
          AdminAuditEvent.record!("users.grant_admin", subject: user.public_id, user: nil, via: "maintenance_task")
        end
      end
    end
  end
end
