module Maintenance
  module Users
    # Upload a CSV with `phone,email` columns. Each matching phone-based user
    # gets the email as pending_email; their first email sign-in verifies and
    # links it (plan section 7.2). Rows whose email already belongs to someone
    # else are skipped (and audited) rather than guessed at.
    class MapPhonesToEmailsTask < MaintenanceTasks::Task
      csv_collection

      def process(row)
        phone = PhoneNumber.normalize(row["phone"])
        email = row["email"].to_s.strip.downcase
        return skip("invalid phone #{row["phone"]}") if phone.nil?
        return skip("invalid email for #{PhoneNumber.mask(phone)}") unless email.match?(URI::MailTo::EMAIL_REGEXP)

        user = ::User.find_by(phone: phone) or return skip("no user with phone #{PhoneNumber.mask(phone)}")
        return if user.email == email

        owner = ::User.where.not(id: user.id).find_by(email: email)
        return skip("#{email} already belongs to #{owner.public_id}; merge manually") if owner

        user.update!(pending_email: email)
      end

      private
        def skip(reason)
          AdminAuditEvent.record!("users.map_phone_skipped", subject: reason, user: nil)
        end
    end
  end
end
