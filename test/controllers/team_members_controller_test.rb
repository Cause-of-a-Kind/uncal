require "test_helper"

class TeamMembersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @owner = users(:one)
    @teammate = users(:two)
  end

  test "requires authentication" do
    delete team_member_path(@teammate)
    assert_redirected_to new_session_path
  end

  test "owner can remove a teammate" do
    sign_in_as @owner

    assert_difference("User.count", -1) do
      delete team_member_path(@teammate)
    end

    assert_redirected_to edit_settings_path
    assert_equal "Team member removed.", flash[:notice]
  end

  test "owner cannot remove themselves" do
    sign_in_as @owner

    assert_no_difference("User.count") do
      delete team_member_path(@owner)
    end

    assert_redirected_to edit_settings_path
    assert_equal "You cannot remove yourself.", flash[:alert]
  end

  test "non-owner cannot remove anyone" do
    sign_in_as @teammate

    assert_no_difference("User.count") do
      delete team_member_path(@owner)
    end

    assert_redirected_to edit_settings_path
    assert_equal "Only the owner can remove team members.", flash[:alert]
  end
end
