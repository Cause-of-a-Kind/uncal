class InvitationMailer < ApplicationMailer
  def invite(invitation)
    @invitation = invitation
    @accept_url = invitation_acceptance_url(token: invitation.token)

    mail to: invitation.email, subject: "You've been invited to Uncal"
  end
end
