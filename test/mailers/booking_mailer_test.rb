require "test_helper"

class BookingMailerTest < ActionMailer::TestCase
  setup do
    @booking = bookings(:confirmed_one)
    @link = @booking.schedule_link
  end

  test "confirmation sent to invitee email" do
    email = BookingMailer.confirmation(@booking)
    assert_equal [ @booking.invitee_email ], email.to
  end

  test "confirmation subject includes meeting name" do
    email = BookingMailer.confirmation(@booking)
    assert_equal "Confirmed: #{@link.meeting_name}", email.subject
  end

  test "confirmation body includes meeting details" do
    email = BookingMailer.confirmation(@booking)
    html = email.html_part.body.to_s

    assert_match @link.meeting_name, html
    assert_match @booking.invitee_name, html
    assert_match @link.meeting_duration_minutes.to_s, html
  end

  test "confirmation body includes cancellation link with valid token" do
    email = BookingMailer.confirmation(@booking)
    html = email.html_part.body.to_s

    assert_match "cancel", html.downcase

    cancellation_url_pattern = /bookings\/#{@booking.id}\/cancel\?token=([^"&]+)/
    match = html.match(cancellation_url_pattern)
    assert match, "Expected cancellation URL with token in email body"

    token = CGI.unescape(match[1])
    verified_id = Rails.application.message_verifier("booking_cancellation").verify(token, purpose: :cancel_booking)
    assert_equal @booking.id, verified_id
  end

  test "confirmation uses branded layout" do
    email = BookingMailer.confirmation(@booking)
    html = email.html_part.body.to_s

    assert_match "Uncal", html
    assert_match "email-wrapper", html
  end

  test "confirmation includes ics attachment" do
    email = BookingMailer.confirmation(@booking)
    ics_attachment = email.attachments["meeting.ics"]
    assert_not_nil ics_attachment, "Expected .ics attachment"
    assert_match "text/calendar", ics_attachment.content_type
    assert_match "BEGIN:VCALENDAR", ics_attachment.body.to_s
    assert_match "BEGIN:VEVENT", ics_attachment.body.to_s
  end

  test "confirmation ics includes meeting details" do
    email = BookingMailer.confirmation(@booking)
    ics_body = email.attachments["meeting.ics"].body.to_s
    assert_match @link.meeting_name, ics_body
  end

  # Host notification tests

  test "host_notification sent to host email" do
    host = users(:one)
    email = BookingMailer.host_notification(@booking, host)
    assert_equal [ host.email_address ], email.to
  end

  test "host_notification subject includes meeting name and invitee" do
    host = users(:one)
    email = BookingMailer.host_notification(@booking, host)
    assert_equal "New booking: #{@link.meeting_name} with #{@booking.invitee_name}", email.subject
  end

  test "host_notification body includes booking details" do
    host = users(:one)
    email = BookingMailer.host_notification(@booking, host)
    html = email.html_part.body.to_s

    assert_match @link.meeting_name, html
    assert_match @booking.invitee_name, html
    assert_match @booking.invitee_email, html
    assert_match host.name, html
  end

  test "host_notification shows time in host timezone" do
    host = users(:one) # America/New_York
    email = BookingMailer.host_notification(@booking, host)
    html = email.html_part.body.to_s

    expected_tz = ActiveSupport::TimeZone[host.timezone]
    assert_match expected_tz.name, html
  end

  test "host_cancellation sent to host email" do
    host = users(:one)
    email = BookingMailer.host_cancellation(@booking, host)
    assert_equal [ host.email_address ], email.to
  end

  test "host_cancellation subject includes meeting name and invitee" do
    host = users(:one)
    email = BookingMailer.host_cancellation(@booking, host)
    assert_equal "Cancelled: #{@link.meeting_name} with #{@booking.invitee_name}", email.subject
  end

  test "host_cancellation body includes booking details" do
    host = users(:one)
    email = BookingMailer.host_cancellation(@booking, host)
    html = email.html_part.body.to_s

    assert_match @link.meeting_name, html
    assert_match @booking.invitee_name, html
    assert_match @booking.invitee_email, html
    assert_match "Cancelled", html
  end

  # Invitee cancellation tests

  test "cancellation sent to invitee email" do
    email = BookingMailer.cancellation(@booking)
    assert_equal [ @booking.invitee_email ], email.to
  end

  test "cancellation subject includes meeting name" do
    email = BookingMailer.cancellation(@booking)
    assert_equal "Cancelled: #{@link.meeting_name}", email.subject
  end

  test "cancellation body includes booking details" do
    email = BookingMailer.cancellation(@booking)
    html = email.html_part.body.to_s

    assert_match @link.meeting_name, html
    assert_match @booking.invitee_name, html
    assert_match "Cancelled", html
  end

  test "cancellation renders text part" do
    email = BookingMailer.cancellation(@booking)
    text = email.text_part.body.to_s

    assert_match @link.meeting_name, text
    assert_match @booking.invitee_name, text
  end
end
