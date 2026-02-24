require "test_helper"

class ScheduleLinkTest < ActiveSupport::TestCase
  test "validates presence of name" do
    link = schedule_links(:one)
    link.name = nil
    assert_not link.valid?
    assert_includes link.errors[:name], "can't be blank"
  end

  test "validates presence of meeting_name" do
    link = schedule_links(:one)
    link.meeting_name = nil
    assert_not link.valid?
    assert_includes link.errors[:meeting_name], "can't be blank"
  end

  test "validates presence of meeting_duration_minutes" do
    link = schedule_links(:one)
    link.meeting_duration_minutes = nil
    assert_not link.valid?
    assert_includes link.errors[:meeting_duration_minutes], "can't be blank"
  end

  test "validates presence of meeting_location_type" do
    link = schedule_links(:one)
    link.meeting_location_type = nil
    assert_not link.valid?
    assert_includes link.errors[:meeting_location_type], "can't be blank"
  end

  test "validates presence of timezone" do
    link = schedule_links(:one)
    link.timezone = nil
    assert_not link.valid?
    assert_includes link.errors[:timezone], "can't be blank"
  end

  test "meeting_duration_minutes must be greater than 0" do
    link = schedule_links(:one)
    link.meeting_duration_minutes = 0
    assert_not link.valid?
    assert_includes link.errors[:meeting_duration_minutes], "must be greater than 0"
  end

  test "max_future_days must be greater than 0" do
    link = schedule_links(:one)
    link.max_future_days = 0
    assert_not link.valid?
    assert_includes link.errors[:max_future_days], "must be greater than 0"
  end

  test "buffer_minutes must be >= 0" do
    link = schedule_links(:one)
    link.buffer_minutes = -1
    assert_not link.valid?
    assert_includes link.errors[:buffer_minutes], "must be greater than or equal to 0"
  end

  test "max_bookings_per_day must be > 0 when present and allows nil" do
    link = schedule_links(:one)
    link.max_bookings_per_day = nil
    assert link.valid?

    link.max_bookings_per_day = 0
    assert_not link.valid?
    assert_includes link.errors[:max_bookings_per_day], "must be greater than 0"
  end

  test "meeting_location_type must be link or physical" do
    link = schedule_links(:one)
    link.meeting_location_type = "phone"
    assert_not link.valid?
    assert_includes link.errors[:meeting_location_type], "is not included in the list"
  end

  test "status defaults to active" do
    link = ScheduleLink.new(
      name: "New Link",
      meeting_name: "Meeting",
      meeting_duration_minutes: 30,
      meeting_location_type: "link",
      timezone: "America/New_York",
      created_by: users(:one)
    )
    assert_equal "active", link.status
  end

  test "slug auto-generated on create" do
    link = ScheduleLink.create!(
      name: "Auto Slug",
      meeting_name: "Meeting",
      meeting_duration_minutes: 30,
      meeting_location_type: "link",
      timezone: "America/New_York",
      created_by: users(:one)
    )
    assert link.slug.present?
    assert_match(/\A[a-z0-9]{8}\z/, link.slug)
  end

  test "slug uniqueness enforced" do
    link = schedule_links(:one)
    duplicate = ScheduleLink.new(
      slug: link.slug,
      name: "Duplicate",
      meeting_name: "Meeting",
      meeting_duration_minutes: 30,
      meeting_location_type: "link",
      timezone: "America/New_York",
      created_by: users(:one)
    )
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:slug], "has already been taken"
  end

  test "belongs to created_by user" do
    link = schedule_links(:one)
    assert_equal users(:one), link.created_by
  end
end
