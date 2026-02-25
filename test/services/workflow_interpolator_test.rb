require "test_helper"

class WorkflowInterpolatorTest < ActiveSupport::TestCase
  setup do
    @booking = bookings(:confirmed_one)
    @interpolator = WorkflowInterpolator.new(@booking)
  end

  test "interpolates invitee_name" do
    assert_equal "Alice Visitor", @interpolator.interpolate("{{invitee_name}}")
  end

  test "interpolates invitee_email" do
    assert_equal "alice@visitor.com", @interpolator.interpolate("{{invitee_email}}")
  end

  test "interpolates meeting_name" do
    assert_equal "Daily Standup", @interpolator.interpolate("{{meeting_name}}")
  end

  test "interpolates meeting_date in link timezone" do
    result = @interpolator.interpolate("{{meeting_date}}")
    # 2026-03-04 14:00 UTC = 2026-03-04 09:00 EST
    assert_equal "March 4, 2026", result
  end

  test "interpolates meeting_time in link timezone" do
    result = @interpolator.interpolate("{{meeting_time}}")
    assert_equal "9:00 AM", result
  end

  test "interpolates meeting_duration" do
    assert_equal "30", @interpolator.interpolate("{{meeting_duration}}")
  end

  test "interpolates meeting_location" do
    assert_equal "https://zoom.us/j/123", @interpolator.interpolate("{{meeting_location}}")
  end

  test "interpolates host_names" do
    result = @interpolator.interpolate("{{host_names}}")
    assert_includes result, "User One"
  end

  test "handles multiple variables in one string" do
    result = @interpolator.interpolate("Hi {{invitee_name}}, your {{meeting_name}} is on {{meeting_date}}")
    assert_equal "Hi Alice Visitor, your Daily Standup is on March 4, 2026", result
  end

  test "leaves unknown variables as-is" do
    assert_equal "{{unknown_var}}", @interpolator.interpolate("{{unknown_var}}")
  end

  test "handles empty location" do
    @booking.schedule_link.update!(meeting_location_value: nil)
    assert_equal "", @interpolator.interpolate("{{meeting_location}}")
  end
end
