module Admin
  class BookingsController < ApplicationController
    before_action :set_booking, only: %i[show cancel]

    def index
      @bookings = scope_bookings
        .includes(schedule_link: :members)

      if params[:schedule_link_id].present?
        @bookings = @bookings.where(schedule_link_id: params[:schedule_link_id])
      end

      if params[:status].present?
        @bookings = @bookings.where(status: params[:status])
      end

      if params[:from].present?
        @bookings = @bookings.where("bookings.start_time >= ?", Date.parse(params[:from]).beginning_of_day)
      end

      if params[:to].present?
        @bookings = @bookings.where("bookings.start_time <= ?", Date.parse(params[:to]).end_of_day)
      end

      @bookings = @bookings.order(start_time: :desc)
      @schedule_links = scope_schedule_links
    end

    def show
      @link = @booking.schedule_link
    end

    def cancel
      if @booking.status == "cancelled"
        redirect_to admin_booking_path(@booking), notice: "This booking was already cancelled."
        return
      end

      @booking.update!(status: "cancelled")

      WorkflowCanceller.new(@booking).cancel_all

      delete_google_calendar_events(@booking)

      date = @booking.start_time.to_date
      @booking.schedule_link.members.each do |member|
        GoogleCalendarService.invalidate_busy_cache(member, date)
      end

      BookingMailer.cancellation(@booking).deliver_later

      @booking.schedule_link.members.each do |member|
        BookingMailer.host_cancellation(@booking, member).deliver_later
      end

      redirect_to admin_booking_path(@booking), notice: "Booking cancelled."
    end

    private

    def scope_bookings
      Booking
        .joins(schedule_link: :schedule_link_members)
        .where(schedule_link_members: { user_id: Current.user.id })
    end

    def scope_schedule_links
      Current.user.schedule_links
    end

    def set_booking
      @booking = scope_bookings.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      head :not_found
    end

    def delete_google_calendar_events(booking)
      if booking.google_calendar_events.exists?
        booking.google_calendar_events.includes(:google_calendar_connection).find_each do |calendar_event|
          connection = calendar_event.google_calendar_connection
          next unless connection.active?

          GoogleCalendarService.new(connection).delete_event(calendar_event.google_event_id)
        rescue => e
          Rails.logger.error "Failed to delete GCal event #{calendar_event.id}: #{e.message}"
        end
        return
      end

      return if booking.google_event_id.blank?

      booking.schedule_link.members.select(&:google_calendar_connected?).each do |member|
        begin
          GoogleCalendarService.new(member.primary_google_calendar_connection || member).delete_event(booking.google_event_id)
        rescue => e
          Rails.logger.error "Failed to delete legacy GCal event for member #{member.id}: #{e.message}"
        end
      end
    end
  end
end
