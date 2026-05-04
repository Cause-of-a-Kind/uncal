class SettingsController < ApplicationController
  def edit
    @user = Current.user
    @google_calendar_connections = @user.google_calendar_connections.active.primary_first
    @team_members = scope_team_members
    @pending_invitations = scope_invitations
  end

  def update
    @user = Current.user

    if @user.update(settings_params)
      redirect_to edit_settings_path, notice: "Settings updated."
    else
      @team_members = scope_team_members
      @google_calendar_connections = @user.google_calendar_connections.active.primary_first
      @pending_invitations = scope_invitations
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def scope_team_members
    User.order(:name)
  end

  def scope_invitations
    Invitation.pending.order(created_at: :desc)
  end

  def settings_params
    params.require(:user).permit(:name, :email_address, :timezone)
  end
end
