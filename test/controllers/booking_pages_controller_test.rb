require "test_helper"

class BookingPagesControllerTest < ActionDispatch::IntegrationTest
  test "renders without authentication" do
    get booking_page_path(slug: schedule_links(:one).slug)
    assert_response :success
  end

  test "displays meeting info" do
    link = schedule_links(:one)
    get booking_page_path(slug: link.slug)

    assert_response :success
    assert_select "h1", link.meeting_name
    assert_match link.meeting_duration_minutes.to_s, response.body
  end

  test "invalid slug returns 404" do
    get booking_page_path(slug: "nonexistent")
    assert_response :not_found
  end

  test "inactive link returns 404" do
    link = schedule_links(:one)
    link.update!(status: "inactive")

    get booking_page_path(slug: link.slug)
    assert_response :not_found
  end
end
