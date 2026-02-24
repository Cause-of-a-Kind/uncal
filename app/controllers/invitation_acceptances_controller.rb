class InvitationAcceptancesController < ApplicationController
  layout "auth"
  allow_unauthenticated_access

  before_action :set_invitation

  def show
  end

  def update
    user = @invitation.accept!(acceptance_params)
    start_new_session_for user
    redirect_to root_path, notice: "Welcome to Uncal!"
  rescue ActiveRecord::RecordInvalid => e
    @user = e.record
    render :show, status: :unprocessable_entity
  end

  private

  def set_invitation
    @invitation = Invitation.find_by!(token: params[:token])

    unless @invitation.pending?
      message = @invitation.accepted? ? "This invitation has already been used." : "This invitation has expired."
      redirect_to new_session_path, alert: message
    end
  rescue ActiveRecord::RecordNotFound
    redirect_to new_session_path, alert: "Invalid invitation link."
  end

  def acceptance_params
    params.require(:invitation_acceptance).permit(:name, :password, :password_confirmation, :timezone)
  end
end
