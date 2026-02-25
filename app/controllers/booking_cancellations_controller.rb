class BookingCancellationsController < ApplicationController
  allow_unauthenticated_access
  layout "public"

  before_action :find_booking
  before_action :verify_token

  def show
  end

  def update
    if @booking.status == "cancelled"
      redirect_to booking_cancellation_path(id: @booking.id, token: params[:token]), notice: "This booking was already cancelled."
      return
    end

    @booking.update!(status: "cancelled")

    # Remove Google Calendar event if present
    if @booking.google_event_id.present?
      @booking.schedule_link.members.select(&:google_calendar_connected?).each do |member|
        begin
          GoogleCalendarService.new(member).delete_event(@booking.google_event_id)
        rescue => e
          Rails.logger.error "Failed to delete GCal event for member #{member.id}: #{e.message}"
        end
      end
    end

    # Invalidate busy caches
    date = @booking.start_time.to_date
    @booking.schedule_link.members.each do |member|
      GoogleCalendarService.invalidate_busy_cache(member, date)
    end

    redirect_to booking_cancellation_path(id: @booking.id, token: params[:token]), notice: "Your booking has been cancelled."
  end

  private

  def find_booking
    @booking = Booking.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    raise ActionController::RoutingError, "Not Found"
  end

  def verify_token
    Rails.application.message_verifier("booking_cancellation").verify(
      params[:token],
      purpose: :cancel_booking
    )
  rescue ActiveSupport::MessageVerifier::InvalidSignature
    raise ActionController::RoutingError, "Not Found"
  end
end
