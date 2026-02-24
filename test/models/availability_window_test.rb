require "test_helper"

class AvailabilityWindowTest < ActiveSupport::TestCase
  test "valid with all required attributes" do
    window = AvailabilityWindow.new(
      schedule_link: schedule_links(:one),
      user: users(:one),
      day_of_week: 1,
      start_time: "09:00",
      end_time: "12:00"
    )
    assert window.valid?
  end

  test "requires schedule_link" do
    window = AvailabilityWindow.new(
      user: users(:one),
      day_of_week: 1,
      start_time: "09:00",
      end_time: "12:00"
    )
    assert_not window.valid?
    assert_includes window.errors[:schedule_link], "must exist"
  end

  test "requires user" do
    window = AvailabilityWindow.new(
      schedule_link: schedule_links(:one),
      day_of_week: 1,
      start_time: "09:00",
      end_time: "12:00"
    )
    assert_not window.valid?
    assert_includes window.errors[:user], "must exist"
  end

  test "requires day_of_week" do
    window = AvailabilityWindow.new(
      schedule_link: schedule_links(:one),
      user: users(:one),
      start_time: "09:00",
      end_time: "12:00"
    )
    assert_not window.valid?
    assert_includes window.errors[:day_of_week], "is not included in the list"
  end

  test "day_of_week must be 0 through 6" do
    window = AvailabilityWindow.new(
      schedule_link: schedule_links(:one),
      user: users(:one),
      start_time: "09:00",
      end_time: "12:00"
    )

    window.day_of_week = -1
    assert_not window.valid?

    window.day_of_week = 7
    assert_not window.valid?

    (0..6).each do |day|
      window.day_of_week = day
      window.valid?
      assert_not window.errors[:day_of_week].any?, "day_of_week #{day} should be valid"
    end
  end

  test "start_time must be before end_time" do
    window = AvailabilityWindow.new(
      schedule_link: schedule_links(:one),
      user: users(:one),
      day_of_week: 1,
      start_time: "14:00",
      end_time: "09:00"
    )
    assert_not window.valid?
    assert_includes window.errors[:start_time], "must be before end time"
  end

  test "start_time equal to end_time is invalid" do
    window = AvailabilityWindow.new(
      schedule_link: schedule_links(:one),
      user: users(:one),
      day_of_week: 1,
      start_time: "09:00",
      end_time: "09:00"
    )
    assert_not window.valid?
    assert_includes window.errors[:start_time], "must be before end time"
  end

  test "rejects overlapping windows for same user, day, and schedule_link" do
    # Fixture: one_monday_morning is 09:00-12:00 for user one on link one, day 0
    window = AvailabilityWindow.new(
      schedule_link: schedule_links(:one),
      user: users(:one),
      day_of_week: 0,
      start_time: "10:00",
      end_time: "14:00"
    )
    assert_not window.valid?
    assert_includes window.errors[:base], "overlaps with an existing availability window"
  end

  test "allows non-overlapping windows on same day" do
    # Fixture: one_monday_morning is 09:00-12:00, one_monday_afternoon is 13:00-17:00
    # Add a gap window between them
    window = AvailabilityWindow.new(
      schedule_link: schedule_links(:one),
      user: users(:one),
      day_of_week: 0,
      start_time: "12:00",
      end_time: "13:00"
    )
    assert window.valid?
  end

  test "allows same times on different days" do
    # Fixture: one_monday_morning is 09:00-12:00 on day 0
    window = AvailabilityWindow.new(
      schedule_link: schedule_links(:one),
      user: users(:one),
      day_of_week: 1,
      start_time: "09:00",
      end_time: "12:00"
    )
    assert window.valid?
  end

  test "allows same times on same day for different users on same link" do
    # Need user two to be a member of link one
    schedule_links(:one).members << users(:two)

    window = AvailabilityWindow.new(
      schedule_link: schedule_links(:one),
      user: users(:two),
      day_of_week: 0,
      start_time: "09:00",
      end_time: "12:00"
    )
    assert window.valid?
  end

  test "belongs_to schedule_link" do
    window = availability_windows(:one_monday_morning)
    assert_equal schedule_links(:one), window.schedule_link
  end

  test "belongs_to user" do
    window = availability_windows(:one_monday_morning)
    assert_equal users(:one), window.user
  end

  test "schedule_link has_many availability_windows" do
    link = schedule_links(:one)
    assert_includes link.availability_windows, availability_windows(:one_monday_morning)
    assert_includes link.availability_windows, availability_windows(:one_monday_afternoon)
    assert_includes link.availability_windows, availability_windows(:one_wednesday)
  end

  test "destroying schedule_link destroys availability_windows" do
    link = schedule_links(:one)
    assert_difference "AvailabilityWindow.count", -3 do
      link.destroy
    end
  end
end
