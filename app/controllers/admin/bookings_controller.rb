module Admin
  class BookingsController < ApplicationController
    before_action :set_booking, only: %i[show cancel]

    def index
      @bookings = user_bookings
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
      @schedule_links = Current.user.schedule_links
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

      if @booking.google_event_id.present?
        @booking.schedule_link.members.select(&:google_calendar_connected?).each do |member|
          begin
            GoogleCalendarService.new(member).delete_event(@booking.google_event_id)
          rescue => e
            Rails.logger.error "Failed to delete GCal event for member #{member.id}: #{e.message}"
          end
        end
      end

      date = @booking.start_time.to_date
      @booking.schedule_link.members.each do |member|
        GoogleCalendarService.invalidate_busy_cache(member, date)
      end

      BookingMailer.cancellation(@booking).deliver_later

      redirect_to admin_booking_path(@booking), notice: "Booking cancelled."
    end

    private

    def user_bookings
      Booking
        .joins(schedule_link: :schedule_link_members)
        .where(schedule_link_members: { user_id: Current.user.id })
    end

    def set_booking
      @booking = user_bookings.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      head :not_found
    end
  end
end
