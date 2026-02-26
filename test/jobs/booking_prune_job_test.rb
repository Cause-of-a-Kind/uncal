require "test_helper"

class BookingPruneJobTest < ActiveJob::TestCase
  test "deletes bookings older than retention period" do
    old_booking = bookings(:old_one)
    assert Booking.exists?(old_booking.id)

    BookingPruneJob.perform_now

    assert_not Booking.exists?(old_booking.id)
  end

  test "keeps recent bookings" do
    upcoming = bookings(:upcoming_one)
    recent = bookings(:recent_one)

    BookingPruneJob.perform_now

    assert Booking.exists?(upcoming.id)
    assert Booking.exists?(recent.id)
  end

  test "does not touch contacts" do
    contact_count = Contact.count
    BookingPruneJob.perform_now
    assert_equal contact_count, Contact.count
  end

  test "respects ENV override" do
    recent = bookings(:recent_one)
    # Set retention to 1 day so the 3-days-ago booking gets pruned
    ENV["BOOKING_RETENTION_DAYS"] = "1"

    BookingPruneJob.perform_now

    assert_not Booking.exists?(recent.id)
  ensure
    ENV.delete("BOOKING_RETENTION_DAYS")
  end

  test "logs pruned count" do
    old_logger = Rails.logger
    log_output = StringIO.new
    Rails.logger = ActiveSupport::Logger.new(log_output)

    BookingPruneJob.perform_now

    assert_match(/BookingPruneJob: pruned \d+ bookings/, log_output.string)
  ensure
    Rails.logger = old_logger
  end
end
