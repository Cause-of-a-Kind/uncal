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
