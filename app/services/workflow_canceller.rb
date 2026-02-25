class WorkflowCanceller
  def initialize(booking)
    @booking = booking
  end

  def cancel_all
    return unless defined?(SolidQueue::Job)

    booking_gid = @booking.to_global_id.to_s
    SolidQueue::Job
      .where(class_name: "WorkflowEmailJob")
      .where(finished_at: nil)
      .where("arguments LIKE ?", "%#{booking_gid}%")
      .find_each(&:discard)
  rescue => e
    Rails.logger.error "WorkflowCanceller error for Booking##{@booking.id}: #{e.message}"
  end
end
