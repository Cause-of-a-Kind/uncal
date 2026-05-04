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

    # Cancel pending workflow emails
    WorkflowCanceller.new(@booking).cancel_all

    delete_google_calendar_events

    # Invalidate busy caches
    date = @booking.start_time.to_date
    @booking.schedule_link.members.each do |member|
      GoogleCalendarService.invalidate_busy_cache(member, date)
    end

    BookingMailer.cancellation(@booking).deliver_later

    @booking.schedule_link.members.each do |member|
      BookingMailer.host_cancellation(@booking, member).deliver_later
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

  def delete_google_calendar_events
    if @booking.google_calendar_events.exists?
      @booking.google_calendar_events.includes(:google_calendar_connection).find_each do |calendar_event|
        connection = calendar_event.google_calendar_connection
        next unless connection.active?

        GoogleCalendarService.new(connection).delete_event(calendar_event.google_event_id)
      rescue => e
        Rails.logger.error "Failed to delete GCal event #{calendar_event.id}: #{e.message}"
      end
      return
    end

    return if @booking.google_event_id.blank?

    @booking.schedule_link.members.select(&:google_calendar_connected?).each do |member|
      begin
        GoogleCalendarService.new(member.primary_google_calendar_connection || member).delete_event(@booking.google_event_id)
      rescue => e
        Rails.logger.error "Failed to delete legacy GCal event for member #{member.id}: #{e.message}"
      end
    end
  end
end
