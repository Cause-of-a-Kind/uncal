class InvitationMailerPreview < ActionMailer::Preview
  def invite
    InvitationMailer.invite(Invitation.first || Invitation.new(email: "test@example.com", token: "preview-token"))
  end
end
