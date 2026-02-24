require "test_helper"

class InvitationTest < ActiveSupport::TestCase
  test "generates token on create" do
    invitation = Invitation.new(email: "new@example.com", invited_by: users(:one))
    invitation.save!
    assert invitation.token.present?
    assert_equal 43, invitation.token.length # urlsafe_base64(32) produces 43 chars
  end

  test "sets expiry to 7 days on create" do
    invitation = Invitation.create!(email: "new@example.com", invited_by: users(:one))
    assert_in_delta 7.days.from_now, invitation.expires_at, 5.seconds
  end

  test "normalizes email" do
    invitation = Invitation.new(email: " TEST@EXAMPLE.COM ")
    assert_equal "test@example.com", invitation.email
  end

  test "validates email presence" do
    invitation = Invitation.new(invited_by: users(:one))
    assert_not invitation.valid?
    assert_includes invitation.errors[:email], "can't be blank"
  end

  test "validates email format" do
    invitation = Invitation.new(email: "not-an-email", invited_by: users(:one))
    assert_not invitation.valid?
    assert_includes invitation.errors[:email], "is invalid"
  end

  test "pending scope" do
    assert_includes Invitation.pending, invitations(:pending)
    assert_not_includes Invitation.pending, invitations(:accepted)
    assert_not_includes Invitation.pending, invitations(:expired)
  end

  test "accepted scope" do
    assert_includes Invitation.accepted, invitations(:accepted)
    assert_not_includes Invitation.accepted, invitations(:pending)
  end

  test "expired scope" do
    assert_includes Invitation.expired, invitations(:expired)
    assert_not_includes Invitation.expired, invitations(:pending)
  end

  test "pending?" do
    assert invitations(:pending).pending?
    assert_not invitations(:accepted).pending?
    assert_not invitations(:expired).pending?
  end

  test "accepted?" do
    assert invitations(:accepted).accepted?
    assert_not invitations(:pending).accepted?
  end

  test "expired?" do
    assert invitations(:expired).expired?
    assert_not invitations(:pending).expired?
  end

  test "accept! creates user and marks accepted" do
    invitation = invitations(:pending)
    user = invitation.accept!(name: "New User", password: "password123", timezone: "America/Chicago")

    assert user.persisted?
    assert_equal "pending@example.com", user.email_address
    assert_equal "New User", user.name
    assert_equal "America/Chicago", user.timezone

    invitation.reload
    assert invitation.accepted?
    assert_not_nil invitation.accepted_at
  end

  test "accept! rolls back on invalid user" do
    invitation = invitations(:pending)

    assert_raises(ActiveRecord::RecordInvalid) do
      invitation.accept!(name: "", password: "password123", timezone: "America/Chicago")
    end

    invitation.reload
    assert invitation.pending?
  end
end
