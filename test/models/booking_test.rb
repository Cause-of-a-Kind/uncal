require "test_helper"

class BookingTest < ActiveSupport::TestCase
  test "valid with all required attributes" do
    booking = Booking.new(
      schedule_link: schedule_links(:one),
      start_time: 1.day.from_now,
      end_time: 1.day.from_now + 30.minutes,
      invitee_name: "Test User",
      invitee_email: "test@example.com",
      invitee_timezone: "America/New_York"
    )
    assert booking.valid?
  end

  test "status defaults to confirmed" do
    booking = Booking.new
    assert_equal "confirmed", booking.status
  end

  test "belongs to schedule_link" do
    booking = bookings(:confirmed_one)
    assert_equal schedule_links(:one), booking.schedule_link
  end

  test "contact is optional" do
    booking = Booking.new(
      schedule_link: schedule_links(:one),
      start_time: 2.days.from_now,
      end_time: 2.days.from_now + 30.minutes,
      invitee_name: "No Contact",
      invitee_email: "nocontact@example.com",
      invitee_timezone: "Etc/UTC"
    )
    assert booking.valid?
    assert_nil booking.contact
  end

  test "confirmed scope excludes cancelled" do
    confirmed = Booking.confirmed
    assert_includes confirmed, bookings(:confirmed_one)
    assert_not_includes confirmed, bookings(:cancelled_one)
  end

  test "requires invitee_name, invitee_email, invitee_timezone" do
    booking = Booking.new(schedule_link: schedule_links(:one), start_time: 1.day.from_now, end_time: 1.day.from_now + 30.minutes)
    assert_not booking.valid?
    assert_includes booking.errors[:invitee_name], "can't be blank"
    assert_includes booking.errors[:invitee_email], "can't be blank"
    assert_includes booking.errors[:invitee_timezone], "can't be blank"
  end
end
