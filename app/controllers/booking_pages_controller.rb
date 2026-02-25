class BookingPagesController < ApplicationController
  allow_unauthenticated_access
  layout "public"

  def show
    @link = ScheduleLink.active.find_by!(slug: params[:slug])
    @members = @link.members
  rescue ActiveRecord::RecordNotFound
    raise ActionController::RoutingError, "Not Found"
  end
end
