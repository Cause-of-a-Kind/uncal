require "test_helper"

class AvailabilityCalculatorTest < ActiveSupport::TestCase
  setup do
    @link_one = schedule_links(:one)  # 30-min, America/New_York, 1 member (user one), buffer 15, max_future 30
    @link_two = schedule_links(:two)  # 60-min, Etc/UTC, 2 members (one + two), max_bookings 3, max_future 60
    @user_one = users(:one)           # America/New_York
    @user_two = users(:two)           # Etc/UTC

    # Default: stub GoogleCalendarService to return no busy times
    @original_gcal_new = GoogleCalendarService.method(:new)
    GoogleCalendarService.define_singleton_method(:new) do |user|
      service = Object.new
      service.define_singleton_method(:busy_times) { |_start, _end| [] }
      service
    end
  end

  teardown do
    GoogleCalendarService.define_singleton_method(:new, @original_gcal_new)
  end

  # Cycle 2: Single member

  test "returns slots for member with one window on Wednesday" do
    # Fixture: one_wednesday — day 2 (Wednesday), 09:00-17:00 ET on link_one
    # 2026-03-04 is a Wednesday
    date = Date.new(2026, 3, 4)

    travel_to Time.utc(2026, 3, 3, 0, 0) do
      result = AvailabilityCalculator.new(@link_one, date).available_slots

      assert result.any?, "Expected slots but got none"
      result.each do |slot|
        assert_kind_of Hash, slot
        assert slot[:start_time].present?
        assert slot[:end_time].present?
        assert_equal 30.minutes, slot[:end_time] - slot[:start_time]
      end
    end
  end

  test "returns empty for past date" do
    date = Date.new(2026, 3, 1) # a past date relative to travel_to

    travel_to Time.utc(2026, 3, 4, 12, 0) do
      result = AvailabilityCalculator.new(@link_one, date).available_slots
      assert_empty result
    end
  end

  test "returns empty for date beyond max_future_days" do
    # link_one has max_future_days: 30
    date = Date.today + 31

    result = AvailabilityCalculator.new(@link_one, date).available_slots
    assert_empty result
  end

  test "subtracts Google Calendar busy times from availability" do
    # Wednesday 2026-03-04, window 09:00-17:00 ET = 14:00-22:00 UTC
    date = Date.new(2026, 3, 4)

    # User one is connected to Google Calendar
    @user_one.update!(
      google_calendar_connected: true,
      google_calendar_token: "token",
      google_calendar_refresh_token: "refresh",
      google_calendar_token_expires_at: 1.hour.from_now
    )

    # Block 15:00-16:00 UTC (10:00-11:00 ET)
    GoogleCalendarService.define_singleton_method(:new) do |user|
      service = Object.new
      service.define_singleton_method(:busy_times) do |_start, _end|
        [ { start: Time.utc(2026, 3, 4, 15, 0), end: Time.utc(2026, 3, 4, 16, 0) } ]
      end
      service
    end

    travel_to Time.utc(2026, 3, 3, 0, 0) do
      result = AvailabilityCalculator.new(@link_one, date).available_slots

      # No slot should start during the busy period
      result.each do |slot|
        busy_start = Time.utc(2026, 3, 4, 15, 0)
        busy_end = Time.utc(2026, 3, 4, 16, 0)
        slot_end = slot[:start_time] + 30.minutes
        # Slot must not overlap with busy period
        refute slot[:start_time] < busy_end && slot_end > busy_start,
          "Slot #{slot[:start_time]} - #{slot_end} overlaps with busy period"
      end
    end
  end

  test "returns empty when no windows for that day" do
    # 2026-03-05 is a Thursday — no windows for user one on link_one
    date = Date.new(2026, 3, 5)

    travel_to Time.utc(2026, 3, 3, 0, 0) do
      result = AvailabilityCalculator.new(@link_one, date).available_slots
      assert_empty result
    end
  end

  test "handles member with multiple windows on same day" do
    # Monday (day 0): one_monday_morning 09:00-12:00 + one_monday_afternoon 13:00-17:00 on link_one
    # 2026-03-02 is a Monday
    date = Date.new(2026, 3, 2)

    travel_to Time.utc(2026, 3, 1, 0, 0) do
      result = AvailabilityCalculator.new(@link_one, date).available_slots

      assert result.any?, "Expected slots for Monday"

      # Verify no slots span the gap (12:00-13:00 ET = 17:00-18:00 UTC)
      result.each do |slot|
        slot_end = slot[:start_time] + 30.minutes
        gap_start = Time.utc(2026, 3, 2, 17, 0)
        gap_end = Time.utc(2026, 3, 2, 18, 0)
        refute slot[:start_time] < gap_end && slot_end > gap_start,
          "Slot should not span the lunch gap"
      end
    end
  end

  test "UTC conversion is correct for America/New_York" do
    # Wednesday window: 09:00-17:00 ET
    # March 4, 2026 is before DST (EST = UTC-5)
    # So 09:00 ET = 14:00 UTC, 17:00 ET = 22:00 UTC
    date = Date.new(2026, 3, 4)

    # Remove fixture bookings for a clean test
    @link_one.bookings.destroy_all

    travel_to Time.utc(2026, 3, 3, 0, 0) do
      result = AvailabilityCalculator.new(@link_one, date).available_slots

      assert result.any?
      first_slot = result.first[:start_time]
      last_slot = result.last[:start_time]

      # First slot should be at 14:00 UTC (09:00 ET)
      assert_equal Time.utc(2026, 3, 4, 14, 0), first_slot
      # Last slot + duration should fit within 22:00 UTC (17:00 ET)
      assert last_slot + 30.minutes <= Time.utc(2026, 3, 4, 22, 0)
    end
  end

  # Cycle 3: Multi-member & constraints

  test "intersects two members — only mutual free times" do
    # link_two has two members: user_one and user_two
    # user_one has Monday window 08:00-11:00 UTC on link_two (fixture two_monday)
    # Add a window for user_two on link_two for Monday
    AvailabilityWindow.create!(
      schedule_link: @link_two,
      user: @user_two,
      day_of_week: 0,
      start_time: "10:00",
      end_time: "14:00"
    )

    # 2026-03-02 is a Monday
    date = Date.new(2026, 3, 2)

    travel_to Time.utc(2026, 3, 1, 0, 0) do
      result = AvailabilityCalculator.new(@link_two, date).available_slots

      assert result.any?, "Expected overlapping slots"

      # link_two timezone is Etc/UTC, so times are direct
      # Overlap: 10:00-11:00 UTC (1 hour, 60-min duration = 1 slot)
      assert_equal 1, result.length
      assert_equal Time.utc(2026, 3, 2, 10, 0), result.first[:start_time]
    end
  end

  test "returns empty when no overlap between members" do
    # user_one: Monday 08:00-11:00 UTC on link_two
    # user_two: Monday 12:00-15:00 UTC — no overlap
    AvailabilityWindow.create!(
      schedule_link: @link_two,
      user: @user_two,
      day_of_week: 0,
      start_time: "12:00",
      end_time: "15:00"
    )

    date = Date.new(2026, 3, 2)

    travel_to Time.utc(2026, 3, 1, 0, 0) do
      result = AvailabilityCalculator.new(@link_two, date).available_slots
      assert_empty result
    end
  end

  test "confirmed booking subtracts time from availability" do
    date = Date.new(2026, 3, 4) # Wednesday

    travel_to Time.utc(2026, 3, 3, 0, 0) do
      # Create a confirmed booking at 16:00-16:30 UTC (11:00-11:30 ET)
      @link_one.bookings.create!(
        start_time: Time.utc(2026, 3, 4, 16, 0),
        end_time: Time.utc(2026, 3, 4, 16, 30),
        invitee_name: "Test", invitee_email: "t@t.com", invitee_timezone: "Etc/UTC"
      )

      result = AvailabilityCalculator.new(@link_one, date).available_slots

      # No slot should start at 16:00 UTC (booked) or during buffer (16:30-16:45)
      result.each do |slot|
        refute slot[:start_time] >= Time.utc(2026, 3, 4, 16, 0) && slot[:start_time] < Time.utc(2026, 3, 4, 16, 45),
          "Slot #{slot[:start_time]} should be blocked by booking + buffer"
      end
    end
  end

  test "cancelled booking does not subtract time" do
    date = Date.new(2026, 3, 4) # Wednesday

    travel_to Time.utc(2026, 3, 3, 0, 0) do
      # The cancelled_one fixture is at 15:00-15:30 UTC on link_one
      slots_without = AvailabilityCalculator.new(@link_one, date).available_slots
      slot_at_15 = slots_without.find { |s| s[:start_time] == Time.utc(2026, 3, 4, 15, 0) }
      assert slot_at_15.present?, "Cancelled booking should not block the 15:00 slot"
    end
  end

  test "max_bookings_per_day returns empty at limit" do
    # link_two has max_bookings_per_day: 3
    # Give user_two a matching window
    AvailabilityWindow.create!(
      schedule_link: @link_two, user: @user_two, day_of_week: 0,
      start_time: "08:00", end_time: "17:00"
    )

    date = Date.new(2026, 3, 2) # Monday

    travel_to Time.utc(2026, 3, 1, 0, 0) do
      3.times do |i|
        @link_two.bookings.create!(
          start_time: Time.utc(2026, 3, 2, 8 + i, 0),
          end_time: Time.utc(2026, 3, 2, 9 + i, 0),
          invitee_name: "Test #{i}", invitee_email: "t#{i}@t.com", invitee_timezone: "Etc/UTC"
        )
      end

      result = AvailabilityCalculator.new(@link_two, date).available_slots
      assert_empty result, "Should return no slots when max_bookings_per_day reached"
    end
  end

  test "max_bookings_per_day set but no bookings still returns slots" do
    # link_two has max_bookings_per_day: 3
    # Add window for user_two so there's overlap
    AvailabilityWindow.create!(
      schedule_link: @link_two,
      user: @user_two,
      day_of_week: 0,
      start_time: "08:00",
      end_time: "11:00"
    )

    date = Date.new(2026, 3, 2) # Monday

    travel_to Time.utc(2026, 3, 1, 0, 0) do
      result = AvailabilityCalculator.new(@link_two, date).available_slots
      assert result.any?, "Should have slots when no bookings exist"
    end
  end

  # Cycle 4: DST & edge cases

  test "DST spring-forward: window contracts by 1hr in UTC" do
    # March 8, 2026 is when US springs forward (EST→EDT)
    # 2026-03-08 is a Sunday — day_of_week 6 in our convention ((0+6)%7 = 6)
    # Create a Sunday window for testing (09:00-17:00 ET = 14:00-22:00 UTC)
    AvailabilityWindow.create!(
      schedule_link: @link_one,
      user: @user_one,
      day_of_week: 6,  # Sunday
      start_time: "14:00",
      end_time: "22:00"
    )

    # On March 7 (before DST): 09:00 EST = 14:00 UTC, 17:00 EST = 22:00 UTC (8hr window)
    # On March 8 (after spring-forward): 09:00 EDT = 13:00 UTC, 17:00 EDT = 21:00 UTC (8hr window)
    # The UTC conversion should reflect EDT (-4) not EST (-5)
    date = Date.new(2026, 3, 8)

    travel_to Time.utc(2026, 3, 7, 0, 0) do
      result = AvailabilityCalculator.new(@link_one, date).available_slots

      assert result.any?
      # First slot should be 13:00 UTC (09:00 EDT)
      assert_equal Time.utc(2026, 3, 8, 13, 0), result.first[:start_time]
    end
  end

  test "late-night window where UTC conversion crosses date boundary" do
    # Create a window at 22:00-23:00 ET for Wednesday (= 03:00-04:00 UTC next day)
    AvailabilityWindow.create!(
      schedule_link: @link_one,
      user: @user_one,
      day_of_week: 2,  # Wednesday
      start_time: "03:00",
      end_time: "04:00"
    )

    # 22:00 EST on March 4 = 03:00 UTC on March 5
    date = Date.new(2026, 3, 4)

    travel_to Time.utc(2026, 3, 3, 0, 0) do
      result = AvailabilityCalculator.new(@link_one, date).available_slots

      # Should have slots from both the 09:00-17:00 window and the 22:00-23:00 window
      late_slots = result.select { |s| s[:start_time] >= Time.utc(2026, 3, 5, 3, 0) }
      assert late_slots.any?, "Should have slots from the late-night window (crossing into next UTC day)"
    end
  end

  test "today's date filters out past slots" do
    # Wednesday March 4, travel to mid-day (15:00 UTC = 10:00 ET)
    date = Date.new(2026, 3, 4)

    travel_to Time.utc(2026, 3, 4, 15, 0) do
      result = AvailabilityCalculator.new(@link_one, date).available_slots

      # All slots should be in the future
      result.each do |slot|
        assert slot[:start_time] > Time.utc(2026, 3, 4, 15, 0),
          "Slot #{slot[:start_time]} should be after current time"
      end

      # Should still have afternoon slots (after 10:00 ET / 15:00 UTC)
      assert result.any?, "Should have future slots for today"
    end
  end
end
