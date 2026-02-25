require "test_helper"

class AvailabilityControllerTest < ActionDispatch::IntegrationTest
  setup do
    @link = schedule_links(:one)  # slug: abc12345, America/New_York
    @link.bookings.destroy_all

    # Stub GoogleCalendarService to return no busy times
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

  test "returns JSON with slots array" do
    # 2026-03-04 is a Wednesday — fixture has 09:00-17:00 ET window
    travel_to Time.utc(2026, 3, 3, 0, 0) do
      get booking_availability_path(slug: @link.slug), params: { date: "2026-03-04" }

      assert_response :success
      json = JSON.parse(response.body)
      assert json.key?("slots")
      assert_kind_of Array, json["slots"]
      assert json["slots"].any?
      assert json["slots"].first.key?("start_time")
      assert json["slots"].first.key?("end_time")
    end
  end

  test "slots are in requester timezone" do
    travel_to Time.utc(2026, 3, 3, 0, 0) do
      get booking_availability_path(slug: @link.slug),
        params: { date: "2026-03-04", timezone: "America/Chicago" }

      assert_response :success
      json = JSON.parse(response.body)

      assert_equal "America/Chicago", json["timezone"]
      # First slot: 09:00 ET = 08:00 CT in ISO8601 with -06:00 offset
      first_start = Time.parse(json["slots"].first["start_time"])
      assert_equal Time.utc(2026, 3, 4, 14, 0), first_start.utc
    end
  end

  test "no authentication required" do
    travel_to Time.utc(2026, 3, 3, 0, 0) do
      get booking_availability_path(slug: @link.slug), params: { date: "2026-03-04" }
      assert_response :success
    end
  end

  test "invalid slug returns 404" do
    get booking_availability_path(slug: "nonexistent"), params: { date: "2026-03-04" }
    assert_response :not_found
  end

  test "missing date returns 400" do
    get booking_availability_path(slug: @link.slug)
    assert_response :bad_request
  end

  test "inactive link returns 404" do
    @link.update!(status: "inactive")

    get booking_availability_path(slug: @link.slug), params: { date: "2026-03-04" }
    assert_response :not_found
  end
end
