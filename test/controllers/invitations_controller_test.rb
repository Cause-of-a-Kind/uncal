require "test_helper"

class InvitationsControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as users(:one)
  end

  test "index requires authentication" do
    sign_out
    get invitations_path
    assert_redirected_to new_session_path
  end

  test "index shows pending invitations" do
    get invitations_path
    assert_response :success
  end

  test "new renders invitation form" do
    get new_invitation_path
    assert_response :success
  end

  test "create sends invitation" do
    assert_difference "Invitation.count", 1 do
      post invitations_path, params: { invitation: { email: "new@example.com" } }
    end

    assert_enqueued_emails 1
    assert_redirected_to invitations_path
    follow_redirect!
    assert_select "div", /Invitation sent/
  end

  test "create with invalid email renders errors" do
    assert_no_difference "Invitation.count" do
      post invitations_path, params: { invitation: { email: "" } }
    end

    assert_response :unprocessable_entity
  end

  test "destroy cancels invitation" do
    invitation = invitations(:pending)

    assert_difference "Invitation.count", -1 do
      delete invitation_path(invitation)
    end

    assert_redirected_to invitations_path
  end
end
