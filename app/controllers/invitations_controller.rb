class InvitationsController < ApplicationController
  def index
    @pending_invitations = scope_invitations
  end

  def new
    @invitation = Invitation.new
  end

  def create
    @invitation = Current.user.sent_invitations.build(invitation_params)

    if @invitation.save
      InvitationMailer.invite(@invitation).deliver_later
      redirect_to invitations_path, notice: "Invitation sent to #{@invitation.email}."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    @invitation = find_invitation(params[:id])
    @invitation.destroy
    redirect_to invitations_path, notice: "Invitation cancelled.", status: :see_other
  end

  private

  def scope_invitations
    Invitation.pending.order(created_at: :desc)
  end

  def find_invitation(id)
    Invitation.find(id)
  end

  def invitation_params
    params.require(:invitation).permit(:email)
  end
end
