class TeamMembersController < ApplicationController
  before_action :require_owner

  def destroy
    user = User.find(params[:id])

    if user == Current.user
      redirect_to edit_settings_path, alert: "You cannot remove yourself."
    else
      user.destroy!
      redirect_to edit_settings_path, notice: "Team member removed."
    end
  end

  private

  def require_owner
    unless Current.user.owner?
      redirect_to edit_settings_path, alert: "Only the owner can remove team members."
    end
  end
end
