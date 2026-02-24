require "test_helper"

class ScheduleLinkMemberTest < ActiveSupport::TestCase
  test "requires schedule_link and user" do
    member = ScheduleLinkMember.new
    assert_not member.valid?
    assert_includes member.errors[:schedule_link], "must exist"
    assert_includes member.errors[:user], "must exist"
  end

  test "schedule_link has_many members through join table" do
    link = schedule_links(:one)
    assert_includes link.members, users(:one)
  end

  test "user has_many schedule_links through join table" do
    user = users(:one)
    assert_includes user.schedule_links, schedule_links(:one)
  end

  test "uniqueness of schedule_link_id and user_id pair" do
    existing = schedule_link_members(:one_on_one)
    duplicate = ScheduleLinkMember.new(
      schedule_link: existing.schedule_link,
      user: existing.user
    )
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:user_id], "has already been taken"
  end
end
