class DashboardController < ApplicationController
  def show
    bookings = scope_bookings.includes(schedule_link: :members)

    @upcoming_bookings = bookings
      .where(status: "confirmed")
      .where("start_time >= ?", Time.current)
      .order(start_time: :asc)
      .limit(10)

    @recent_bookings = bookings
      .where("start_time < ?", Time.current)
      .order(start_time: :desc)
      .limit(5)

    @bookings_this_week = bookings
      .where(status: "confirmed")
      .where(start_time: Time.current.beginning_of_week..Time.current.end_of_week)
      .count

    @schedule_links_count = scope_schedule_links_count
  end

  private

  def scope_bookings
    Booking
      .joins(schedule_link: :schedule_link_members)
      .where(schedule_link_members: { user_id: Current.user.id })
  end

  def scope_schedule_links_count
    Current.user.schedule_links.count
  end
end
