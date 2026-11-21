require "test_helper"

class MembershipMailerTest < ActionMailer::TestCase
  test "invited explains the role and how to sign in" do
    membership = memberships(:carol_scorekeeper)
    membership.user.update!(email: "carol@example.com")
    mail = MembershipMailer.with(membership: membership, invited_by: users(:organizer)).invited

    assert_equal [ "carol@example.com" ], mail.to
    assert_equal "You're helping run 2027 Clinelympic Games on Scorebot 9000", mail.subject
    [ mail.html_part, mail.text_part ].each do |part|
      body = part.body.to_s
      assert_match(/added you as a scorekeeper for (<strong>)?2027 Clinelympic Games/, body)
      assert_match "enter and fix scores", body
      assert_match "http://example.com/session/new", body
      assert_match "http://example.com/manage/events/#{membership.resource.slug}", body
    end
  end

  test "uses 'an' for organizer and owner" do
    membership = memberships(:carol_scorekeeper)
    membership.update!(role: "organizer")
    membership.user.update!(email: "carol@example.com")
    assert_match "as an organizer", MembershipMailer.with(membership: membership, invited_by: nil).invited.text_part.body.to_s
  end
end
