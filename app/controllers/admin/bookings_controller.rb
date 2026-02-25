module Admin
  class BookingsController < ApplicationController
    def index
      @bookings = Booking
        .joins(schedule_link: :schedule_link_members)
        .where(schedule_link_members: { user_id: Current.user.id })
        .includes(schedule_link: :members)
        .order(start_time: :desc)
    end

    def show
      @booking = Booking
        .joins(schedule_link: :schedule_link_members)
        .where(schedule_link_members: { user_id: Current.user.id })
        .find(params[:id])
      @link = @booking.schedule_link
    end
  end
end
