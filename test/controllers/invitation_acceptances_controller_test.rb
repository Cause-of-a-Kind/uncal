require "test_helper"

class InvitationAcceptancesControllerTest < ActionDispatch::IntegrationTest
  test "show renders registration form for pending invitation" do
    get invitation_acceptance_path(token: invitations(:pending).token)
    assert_response :success
    assert_select "input[readonly]"
  end

  test "show redirects for expired invitation" do
    get invitation_acceptance_path(token: invitations(:expired).token)
    assert_redirected_to new_session_path
    follow_redirect!
    assert_select "div", /expired/
  end

  test "show redirects for accepted invitation" do
    get invitation_acceptance_path(token: invitations(:accepted).token)
    assert_redirected_to new_session_path
    follow_redirect!
    assert_select "div", /already been used/
  end

  test "show redirects for invalid token" do
    get invitation_acceptance_path(token: "bogus")
    assert_redirected_to new_session_path
    follow_redirect!
    assert_select "div", /Invalid/
  end

  test "update creates user and logs in" do
    invitation = invitations(:pending)

    assert_difference "User.count", 1 do
      patch invitation_acceptance_path(token: invitation.token), params: {
        invitation_acceptance: {
          name: "New User",
          password: "password123",
          password_confirmation: "password123",
          timezone: "America/Chicago"
        }
      }
    end

    assert_redirected_to root_path
    assert cookies[:session_id]

    user = User.find_by(email_address: invitation.email)
    assert_equal "New User", user.name
    assert_equal "America/Chicago", user.timezone

    invitation.reload
    assert invitation.accepted?
  end

  test "update with invalid params re-renders form" do
    invitation = invitations(:pending)

    assert_no_difference "User.count" do
      patch invitation_acceptance_path(token: invitation.token), params: {
        invitation_acceptance: {
          name: "",
          password: "password123",
          password_confirmation: "password123",
          timezone: "America/Chicago"
        }
      }
    end

    assert_response :unprocessable_entity
  end
end
