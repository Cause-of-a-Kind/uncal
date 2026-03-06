class BookingMailerPreview < ActionMailer::Preview
  def confirmation
    BookingMailer.confirmation(Booking.find_by(status: "confirmed") || Booking.first)
  end

  def cancellation
    BookingMailer.cancellation(Booking.first)
  end

  def host_notification
    booking = Booking.find_by(status: "confirmed") || Booking.first
    BookingMailer.host_notification(booking, booking.schedule_link.members.first)
  end

  def host_cancellation
    booking = Booking.first
    BookingMailer.host_cancellation(booking, booking.schedule_link.members.first)
  end
end
