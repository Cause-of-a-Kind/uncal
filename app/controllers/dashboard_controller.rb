class DashboardController < ApplicationController
  def show
    user_bookings = Booking
      .joins(schedule_link: :schedule_link_members)
      .where(schedule_link_members: { user_id: Current.user.id })
      .includes(schedule_link: :members)

    @upcoming_bookings = user_bookings
      .where(status: "confirmed")
      .where("start_time >= ?", Time.current)
      .order(start_time: :asc)
      .limit(10)

    @recent_bookings = user_bookings
      .where("start_time < ?", Time.current)
      .order(start_time: :desc)
      .limit(5)

    @bookings_this_week = user_bookings
      .where(status: "confirmed")
      .where(start_time: Time.current.beginning_of_week..Time.current.end_of_week)
      .count

    @schedule_links_count = Current.user.schedule_links.count
  end
end
