# Preview at /rails/mailers/membership_mailer/invited in development.
class MembershipMailerPreview < ActionMailer::Preview
  def invited
    membership = Membership.where(resource_type: "Event").where.not(role: "owner").first ||
      Membership.new(role: "scorekeeper", user: User.new(email: "helper@example.com"), resource: Event.first)
    MembershipMailer.with(membership: membership, invited_by: User.first).invited
  end
end
