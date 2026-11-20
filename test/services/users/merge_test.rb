require "test_helper"

module Users
  class MergeTest < ActiveSupport::TestCase
    test "moves registrations and contact details, then deletes the duplicate" do
      keep = users(:player)
      duplicate = users(:alice)
      Merge.call(keep: keep, duplicate: duplicate)
      assert_not User.exists?(duplicate.id)
      assert_equal "+19095550111", keep.reload.phone
      assert_includes keep.participants, participants(:alice)
      assert_equal "Pat Player", keep.name
    end

    test "refuses to merge two registrations for the same event" do
      assert_raises(Merge::Conflict) { Merge.call(keep: users(:alice), duplicate: users(:bob)) }
    end

    test "keeps the stronger membership" do
      Membership.create!(user: users(:dave), resource: events(:clinelympics_2027), role: "owner")
      Merge.call(keep: users(:organizer), duplicate: users(:dave))
      assert_equal "owner", users(:organizer).memberships.find_by(resource: events(:clinelympics_2027))&.role
    end
  end
end
