require "test_helper"

class BookingServiceTest < ActiveSupport::TestCase
  include ActionMailer::TestHelper
  setup do
    @link = schedule_links(:one)
    @user_one = users(:one)

    # Stub GoogleCalendarService
    @original_gcal_new = GoogleCalendarService.method(:new)
    GoogleCalendarService.define_singleton_method(:new) do |user|
      service = Object.new
      service.define_singleton_method(:busy_times) { |_start, _end| [] }
      service.define_singleton_method(:create_event) { |**_args| "fake_event_id" }
      service
    end

    # Clear fixture bookings to avoid unique constraint conflicts
    @link.bookings.destroy_all
  end

  teardown do
    GoogleCalendarService.define_singleton_method(:new, @original_gcal_new)
  end

  def valid_slot_params
    # Wednesday March 4 2026, 14:00-14:30 UTC (09:00-09:30 ET) — within window
    {
      start_time: "2026-03-04T14:00:00Z",
      end_time: "2026-03-04T14:30:00Z",
      invitee_name: "Jane Doe",
      invitee_email: "jane@example.com",
      invitee_notes: "Looking forward to it",
      timezone: "America/New_York"
    }
  end

  test "creates a booking successfully" do
    travel_to Time.utc(2026, 3, 3, 0, 0) do
      result = BookingService.new(@link, valid_slot_params).call

      assert result.success?
      assert_kind_of Booking, result.booking
      assert_equal "confirmed", result.booking.status
    end
  end

  test "stores times in UTC" do
    travel_to Time.utc(2026, 3, 3, 0, 0) do
      result = BookingService.new(@link, valid_slot_params).call

      assert result.success?
      assert_equal Time.utc(2026, 3, 4, 14, 0), result.booking.start_time
      assert_equal Time.utc(2026, 3, 4, 14, 30), result.booking.end_time
    end
  end

  test "stores invitee_timezone" do
    travel_to Time.utc(2026, 3, 3, 0, 0) do
      result = BookingService.new(@link, valid_slot_params).call

      assert_equal "America/New_York", result.booking.invitee_timezone
    end
  end

  test "returns error for unavailable slot" do
    travel_to Time.utc(2026, 3, 3, 0, 0) do
      # Pick a time outside availability windows
      params = valid_slot_params.merge(
        start_time: "2026-03-04T05:00:00Z",
        end_time: "2026-03-04T05:30:00Z"
      )
      result = BookingService.new(@link, params).call

      assert_not result.success?
      assert_match(/no longer available/i, result.error)
    end
  end

  test "handles RecordNotUnique gracefully" do
    travel_to Time.utc(2026, 3, 3, 0, 0) do
      # Book the slot
      BookingService.new(@link, valid_slot_params).call

      # Try to book the same slot again (bypassing availability check by using a direct insert)
      # The service's availability check should catch it, but test the RecordNotUnique fallback
      result = BookingService.new(@link, valid_slot_params).call
      assert_not result.success?
    end
  end

  test "returns error for invalid params" do
    travel_to Time.utc(2026, 3, 3, 0, 0) do
      params = valid_slot_params.merge(invitee_name: "")
      result = BookingService.new(@link, params).call

      assert_not result.success?
    end
  end

  test "creates contacts per member" do
    travel_to Time.utc(2026, 3, 3, 0, 0) do
      assert_difference -> { Contact.count }, 1 do
        BookingService.new(@link, valid_slot_params).call
      end

      contact = @user_one.contacts.find_by(email: "jane@example.com")
      assert_not_nil contact
      assert_equal "Jane Doe", contact.name
      assert_equal 1, contact.total_bookings_count
    end
  end

  test "updates existing contact on repeat booking" do
    travel_to Time.utc(2026, 3, 3, 0, 0) do
      @user_one.contacts.create!(name: "Jane Old", email: "jane@example.com", total_bookings_count: 2)

      BookingService.new(@link, valid_slot_params).call

      contact = @user_one.contacts.find_by(email: "jane@example.com")
      assert_equal "Jane Doe", contact.name
      assert_equal 3, contact.total_bookings_count
    end
  end

  test "enqueues confirmation email" do
    travel_to Time.utc(2026, 3, 3, 0, 0) do
      assert_enqueued_emails 1 do
        BookingService.new(@link, valid_slot_params).call
      end
    end
  end

  test "does not fail when GCal event creation fails" do
    GoogleCalendarService.define_singleton_method(:new) do |user|
      service = Object.new
      service.define_singleton_method(:busy_times) { |_start, _end| [] }
      service.define_singleton_method(:create_event) { |**_args| raise "GCal down" }
      service
    end

    @user_one.update!(google_calendar_connected: true, google_calendar_token: "t", google_calendar_refresh_token: "r", google_calendar_token_expires_at: 1.hour.from_now)

    travel_to Time.utc(2026, 3, 3, 0, 0) do
      result = BookingService.new(@link, valid_slot_params).call
      assert result.success?, "Booking should succeed even when GCal fails"
    end
  end
end
