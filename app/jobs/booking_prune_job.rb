class BookingPruneJob < ApplicationJob
  queue_as :default

  def perform
    retention_days = ENV.fetch("BOOKING_RETENTION_DAYS", 90).to_i
    cutoff = retention_days.days.ago
    count = Booking.where("start_time < ?", cutoff).delete_all
    Rails.logger.info "BookingPruneJob: pruned #{count} bookings older than #{retention_days} days"
  end
end
