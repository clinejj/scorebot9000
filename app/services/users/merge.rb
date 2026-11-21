module Users
  # Merges `duplicate` into `keep` (e.g. a legacy phone-only player and the
  # same person's email account): moves registrations, roles and history,
  # copies missing contact details, then deletes the duplicate.
  class Merge
    class Conflict < StandardError; end

    def self.call(keep:, duplicate:, by: nil)
      new(keep, duplicate, by).call
    end

    def initialize(keep, duplicate, by)
      @keep = keep
      @duplicate = duplicate
      @by = by
    end

    def call
      raise Conflict, "Can't merge a user into themselves" if @keep == @duplicate

      shared_events = @keep.participants.pluck(:event_id) & @duplicate.participants.pluck(:event_id)
      if shared_events.any?
        names = Event.where(id: shared_events).pluck(:name).to_sentence
        raise Conflict, "Both accounts are registered for #{names}; remove one registration first"
      end

      ApplicationRecord.transaction do
        @duplicate.participants.update_all(user_id: @keep.id, updated_at: Time.current)
        move_memberships
        @duplicate.host_requests.update_all(user_id: @keep.id)
        @duplicate.sms_messages.update_all(user_id: @keep.id)
        ScoreEntry.where(submitted_by_user_id: @duplicate.id).update_all(submitted_by_user_id: @keep.id)
        @duplicate.sessions.delete_all

        contact = {
          email: @keep.email || @duplicate.email,
          phone: @keep.phone || @duplicate.phone,
          name: @keep.name.presence || @duplicate.name,
          email_verified_at: @keep.email_verified_at || (@duplicate.email_verified_at if @keep.email.nil?),
          phone_verified_at: @keep.phone_verified_at || (@duplicate.phone_verified_at if @keep.phone.nil?),
          legacy_player_id: @keep.legacy_player_id || @duplicate.legacy_player_id,
          platform_admin: @keep.platform_admin? || @duplicate.platform_admin?
        }
        @duplicate.destroy!
        @keep.update!(contact.merge(placeholder: false))
        AdminAuditEvent.record!("users.merge", subject: @keep.public_id, user: @by, merged: @duplicate.public_id)
      end
      @keep
    end

    private
      def move_memberships
        @duplicate.memberships.find_each do |membership|
          existing = @keep.memberships.find_by(resource_type: membership.resource_type, resource_id: membership.resource_id)
          if existing.nil?
            membership.update!(user: @keep)
          elsif Membership::ROLES.index(membership.role) > Membership::ROLES.index(existing.role)
            existing.update!(role: membership.role)
          end
        end
      end
  end
end
