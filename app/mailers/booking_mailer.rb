class BookingMailer < ApplicationMailer
  def confirmation(booking)
    @booking = booking
    @link = booking.schedule_link
    @timezone = ActiveSupport::TimeZone[@booking.invitee_timezone]
    @members = @link.members

    @cancellation_url = booking_cancellation_url(
      id: @booking.id,
      token: cancellation_token(@booking)
    )

    mail(
      to: @booking.invitee_email,
      subject: "Confirmed: #{@link.meeting_name}"
    )
  end

  def cancellation(booking)
    @booking = booking
    @link = booking.schedule_link
    @timezone = ActiveSupport::TimeZone[@booking.invitee_timezone]
    @members = @link.members

    mail(
      to: @booking.invitee_email,
      subject: "Cancelled: #{@link.meeting_name}"
    )
  end

  private

  def cancellation_token(booking)
    Rails.application.message_verifier("booking_cancellation").generate(
      booking.id,
      purpose: :cancel_booking,
      expires_in: 30.days
    )
  end
end
