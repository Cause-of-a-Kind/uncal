require "test_helper"

class ContactsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    sign_in_as @user
  end

  test "index requires authentication" do
    sign_out
    get contacts_path
    assert_redirected_to new_session_path
  end

  test "index lists contacts sorted by last_booked_at desc" do
    get contacts_path
    assert_response :success
    assert_match contacts(:one_alice).name, response.body
    assert_match contacts(:one_bob).name, response.body
  end

  test "index does not show other users contacts" do
    get contacts_path
    assert_response :success
    assert_no_match contacts(:two_bob).name, response.body
  end

  test "index searches by name" do
    get contacts_path, params: { q: "Alice" }
    assert_response :success
    assert_match contacts(:one_alice).name, response.body
    assert_no_match contacts(:one_bob).name, response.body
  end

  test "index searches by email" do
    get contacts_path, params: { q: "bob@contact" }
    assert_response :success
    assert_match contacts(:one_bob).name, response.body
    assert_no_match contacts(:one_alice).name, response.body
  end

  test "show displays contact details" do
    contact = contacts(:one_alice)
    get contact_path(contact)
    assert_response :success
    assert_match contact.name, response.body
    assert_match contact.email, response.body
  end

  test "show displays booking history" do
    contact = contacts(:one_alice)
    get contact_path(contact)
    assert_response :success
    assert_match bookings(:confirmed_one).invitee_name, response.body
  end

  test "show returns 404 for other users contact" do
    get contact_path(contacts(:two_bob))
    assert_response :not_found
  end

  test "update saves notes" do
    contact = contacts(:one_alice)
    patch contact_path(contact), params: { contact: { notes: "VIP client" } }
    assert_redirected_to contact_path(contact)
    assert_equal "VIP client", contact.reload.notes
  end

  test "update returns 404 for other users contact" do
    patch contact_path(contacts(:two_bob)), params: { contact: { notes: "hacked" } }
    assert_response :not_found
  end
end
