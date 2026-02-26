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

  test "export requires authentication" do
    sign_out
    get export_contacts_path
    assert_redirected_to new_session_path
  end

  test "export returns CSV with correct content type and filename" do
    get export_contacts_path
    assert_response :success
    assert_equal "text/csv", response.content_type
    assert_match 'filename="contacts.csv"', response.headers["Content-Disposition"]
  end

  test "export includes correct headers and contact data" do
    get export_contacts_path
    csv = CSV.parse(response.body)
    assert_equal %w[Name Email Total\ Bookings Last\ Booked Notes Created\ At], csv.first

    alice = contacts(:one_alice)
    alice_row = csv.find { |row| row[1] == alice.email }
    assert_not_nil alice_row
    assert_equal alice.name, alice_row[0]
    assert_equal alice.total_bookings_count.to_s, alice_row[2]
  end

  test "export only includes current users contacts" do
    get export_contacts_path
    csv = CSV.parse(response.body)
    emails = csv.drop(1).map { |row| row[1] }
    assert_includes emails, contacts(:one_alice).email
    assert_includes emails, contacts(:one_bob).email
    assert_not_includes emails, contacts(:two_bob).email
  end
end
