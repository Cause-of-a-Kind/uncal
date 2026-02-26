require "test_helper"

class ErrorHandlingTest < ActionDispatch::IntegrationTest
  test "inactive slug shows friendly 404" do
    link = schedule_links(:one)
    link.update!(status: "inactive")

    get booking_page_path(slug: link.slug)
    assert_response :not_found
    assert_match "Page Not Found", response.body
    assert_match "no longer active", response.body
  end

  test "nonexistent slug shows friendly 404" do
    get booking_page_path(slug: "nonexistent-slug")
    assert_response :not_found
    assert_match "Page Not Found", response.body
  end

  test "active slug shows booking page" do
    link = schedule_links(:one)
    get booking_page_path(slug: link.slug)
    assert_response :success
  end
end
