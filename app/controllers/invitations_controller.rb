class InvitationsController < ApplicationController
  def index
    @pending_invitations = Invitation.pending.order(created_at: :desc)
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
    @invitation = Invitation.find(params[:id])
    @invitation.destroy
    redirect_to invitations_path, notice: "Invitation cancelled.", status: :see_other
  end

  private

  def invitation_params
    params.require(:invitation).permit(:email)
  end
end
