class BookingsController < ApplicationController
  allow_unauthenticated_access
  layout "public"

  def create
    @link = ScheduleLink.active.find_by!(slug: params[:slug])

    result = BookingService.new(@link, booking_params).call

    if result.success?
      redirect_to booking_confirmation_path(slug: @link.slug, id: result.booking.id)
    else
      flash.now[:alert] = result.error
      @members = @link.members
      render "booking_pages/show", status: :unprocessable_entity
    end
  rescue ActiveRecord::RecordNotFound
    raise ActionController::RoutingError, "Not Found"
  end

  def confirmation
    @link = ScheduleLink.find_by!(slug: params[:slug])
    @booking = @link.bookings.find(params[:id])
    @timezone = ActiveSupport::TimeZone[@booking.invitee_timezone]
  rescue ActiveRecord::RecordNotFound
    raise ActionController::RoutingError, "Not Found"
  end

  private

  def booking_params
    params.permit(:start_time, :end_time, :invitee_name, :invitee_email, :invitee_notes, :timezone)
  end
end
