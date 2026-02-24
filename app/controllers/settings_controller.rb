class SettingsController < ApplicationController
  def edit
    @user = Current.user
    @team_members = User.order(:name)
    @pending_invitations = Invitation.pending.order(created_at: :desc)
  end

  def update
    @user = Current.user

    if @user.update(settings_params)
      redirect_to edit_settings_path, notice: "Settings updated."
    else
      @team_members = User.order(:name)
      @pending_invitations = Invitation.pending.order(created_at: :desc)
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def settings_params
    params.require(:user).permit(:name, :email_address, :timezone)
  end
end
