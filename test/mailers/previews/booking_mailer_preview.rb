class BookingMailerPreview < ActionMailer::Preview
  def confirmation
    BookingMailer.confirmation(Booking.find_by(status: "confirmed") || Booking.first)
  end

  def cancellation
    BookingMailer.cancellation(Booking.first)
  end
end
