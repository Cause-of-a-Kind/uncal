require "test_helper"

class BookingCancellationsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @booking = bookings(:confirmed_one)
    @token = Rails.application.message_verifier("booking_cancellation").generate(
      @booking.id,
      purpose: :cancel_booking,
      expires_in: 30.days
    )
  end

  test "valid token renders cancellation page" do
    get booking_cancellation_path(id: @booking.id, token: @token)
    assert_response :success
    assert_match "Cancel Booking", response.body
  end

  test "invalid token returns 404" do
    get booking_cancellation_path(id: @booking.id, token: "invalid_token")
    assert_response :not_found
  end

  test "POST cancels booking" do
    post booking_cancellation_path(id: @booking.id, token: @token)

    assert_redirected_to booking_cancellation_path(id: @booking.id, token: @token)
    @booking.reload
    assert_equal "cancelled", @booking.status
  end

  test "already cancelled booking shows message" do
    @booking.update!(status: "cancelled")

    get booking_cancellation_path(id: @booking.id, token: @token)
    assert_response :success
    assert_match "Already Cancelled", response.body
  end

  test "cancelled slot becomes available again" do
    link = @booking.schedule_link

    # Stub GoogleCalendarService
    original_gcal_new = GoogleCalendarService.method(:new)
    GoogleCalendarService.define_singleton_method(:new) do |user|
      service = Object.new
      service.define_singleton_method(:busy_times) { |_start, _end| [] }
      service
    end

    travel_to Time.utc(2026, 3, 3, 0, 0) do
      # Before cancellation — slot is taken
      slots = AvailabilityCalculator.new(link, Date.new(2026, 3, 4)).available_slots
      slot_at_14 = slots.find { |s| s[:start_time] == Time.utc(2026, 3, 4, 14, 0) }
      assert_nil slot_at_14, "Booked slot should not be available"

      # Cancel
      post booking_cancellation_path(id: @booking.id, token: @token)

      # After cancellation — slot is available again
      slots = AvailabilityCalculator.new(link, Date.new(2026, 3, 4)).available_slots
      slot_at_14 = slots.find { |s| s[:start_time] == Time.utc(2026, 3, 4, 14, 0) }
      assert_not_nil slot_at_14, "Cancelled slot should be available again"
    end

    GoogleCalendarService.define_singleton_method(:new, original_gcal_new)
  end

  test "cancellation invokes workflow canceller" do
    # WorkflowCanceller should not raise during cancellation
    post booking_cancellation_path(id: @booking.id, token: @token)
    assert_redirected_to booking_cancellation_path(id: @booking.id, token: @token)
    assert_equal "cancelled", @booking.reload.status
  end

  test "nonexistent booking returns 404" do
    get booking_cancellation_path(id: 999999, token: @token)
    assert_response :not_found
  end
end
