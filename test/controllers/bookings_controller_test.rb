require "test_helper"

class BookingsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @link = schedule_links(:one)
    @link.bookings.destroy_all

    # Stub GoogleCalendarService
    @original_gcal_new = GoogleCalendarService.method(:new)
    GoogleCalendarService.define_singleton_method(:new) do |user|
      service = Object.new
      service.define_singleton_method(:busy_times) { |_start, _end| [] }
      service.define_singleton_method(:create_event) { |**_args| nil }
      service
    end
  end

  teardown do
    GoogleCalendarService.define_singleton_method(:new, @original_gcal_new)
  end

  test "valid POST creates booking and redirects to confirmation" do
    travel_to Time.utc(2026, 3, 3, 0, 0) do
      assert_difference "Booking.count", 1 do
        post bookings_path(slug: @link.slug), params: {
          start_time: "2026-03-04T14:00:00Z",
          end_time: "2026-03-04T14:30:00Z",
          invitee_name: "Jane Doe",
          invitee_email: "jane@example.com",
          timezone: "America/New_York"
        }
      end

      booking = Booking.last
      assert_redirected_to booking_confirmation_path(slug: @link.slug, id: booking.id)
    end
  end

  test "confirmation page renders" do
    booking = @link.bookings.create!(
      start_time: Time.utc(2026, 3, 4, 14, 0),
      end_time: Time.utc(2026, 3, 4, 14, 30),
      invitee_name: "Jane", invitee_email: "jane@example.com", invitee_timezone: "America/New_York"
    )

    get booking_confirmation_path(slug: @link.slug, id: booking.id)
    assert_response :success
    assert_match "Booking Confirmed", response.body
  end

  test "missing fields returns 422" do
    travel_to Time.utc(2026, 3, 3, 0, 0) do
      post bookings_path(slug: @link.slug), params: {
        start_time: "2026-03-04T14:00:00Z",
        end_time: "2026-03-04T14:30:00Z",
        timezone: "America/New_York"
      }

      assert_response :unprocessable_entity
    end
  end

  test "invalid slug returns 404" do
    post bookings_path(slug: "nonexistent"), params: {
      start_time: "2026-03-04T14:00:00Z",
      end_time: "2026-03-04T14:30:00Z",
      invitee_name: "Jane", invitee_email: "jane@example.com", timezone: "America/New_York"
    }

    assert_response :not_found
  end

  test "slot taken returns 422" do
    travel_to Time.utc(2026, 3, 3, 0, 0) do
      params = {
        start_time: "2026-03-04T14:00:00Z",
        end_time: "2026-03-04T14:30:00Z",
        invitee_name: "Jane", invitee_email: "jane@example.com", timezone: "America/New_York"
      }

      post bookings_path(slug: @link.slug), params: params
      assert_response :redirect

      # Second booking at same slot
      post bookings_path(slug: @link.slug), params: params.merge(invitee_email: "other@example.com")
      assert_response :unprocessable_entity
    end
  end
end
