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

    # Google's invitation is authoritative when the creator's event exists.
    # Otherwise send an iTIP request so other calendar clients can accept it.
    method = booking.google_event_id.present? ? :publish : :request
    attachments["meeting.ics"] = {
      mime_type: "text/calendar; method=#{method.to_s.upcase}",
      content: IcsGenerator.new(booking, method: method).generate
    }

    mail(
      to: @booking.invitee_email,
      subject: "Confirmed: #{@link.meeting_name}"
    )
  end

  def host_notification(booking, host)
    @booking = booking
    @link = booking.schedule_link
    @host = host
    @timezone = ActiveSupport::TimeZone[host.timezone]

    mail(
      to: host.email_address,
      subject: "New booking: #{@link.meeting_name} with #{@booking.invitee_name}"
    )
  end

  def host_cancellation(booking, host)
    @booking = booking
    @link = booking.schedule_link
    @host = host
    @timezone = ActiveSupport::TimeZone[host.timezone]

    mail(
      to: host.email_address,
      subject: "Cancelled: #{@link.meeting_name} with #{@booking.invitee_name}"
    )
  end

  def cancellation(booking)
    @booking = booking
    @link = booking.schedule_link
    @timezone = ActiveSupport::TimeZone[@booking.invitee_timezone]
    @members = @link.members

    if booking.google_event_id.blank?
      attachments["meeting.ics"] = {
        mime_type: "text/calendar; method=CANCEL",
        content: IcsGenerator.new(booking, method: :cancel).generate
      }
    end

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
