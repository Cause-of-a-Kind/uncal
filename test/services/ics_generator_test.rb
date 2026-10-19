require "test_helper"

class IcsGeneratorTest < ActiveSupport::TestCase
  test "generates valid ics for link location type" do
    booking = bookings(:confirmed_one)
    ics = IcsGenerator.new(booking).generate

    assert_match "BEGIN:VCALENDAR", ics
    assert_match "BEGIN:VEVENT", ics
    assert_match "SUMMARY:#{booking.schedule_link.meeting_name}", ics
    assert_match "LOCATION:https://zoom.us/j/123", ics
    assert_match "END:VCALENDAR", ics
  end

  test "published calendar attachment has a stable UID and no scheduling request" do
    booking = bookings(:confirmed_one)
    first = IcsGenerator.new(booking).generate
    second = IcsGenerator.new(booking).generate

    assert_match(/\r?\nMETHOD:PUBLISH\r?\n/, first)
    assert_no_match(/\r?\nATTENDEE[;:]/, first)
    assert_equal first[/^UID:(.+)$/, 1], second[/^UID:(.+)$/, 1]
  end

  test "request includes the guest and has the same UID as a cancellation" do
    booking = bookings(:confirmed_one)
    request = IcsGenerator.new(booking, method: :request).generate
    cancellation = IcsGenerator.new(booking, method: :cancel).generate

    assert_match(/\r?\nMETHOD:REQUEST\r?\n/, request)
    assert_includes request, "mailto:#{booking.invitee_email}"
    assert_match(/\r?\nMETHOD:CANCEL\r?\n/, cancellation)
    assert_match(/\r?\nSTATUS:CANCELLED\r?\n/, cancellation)
    assert_equal request[/^UID:(.+)$/, 1], cancellation[/^UID:(.+)$/, 1]
  end

  test "generates valid ics for physical location type" do
    booking = bookings(:confirmed_one)
    booking.schedule_link.update!(meeting_location_type: "physical", meeting_location_value: "123 Main St")
    ics = IcsGenerator.new(booking).generate

    assert_match "LOCATION:123 Main St", ics
  end

  test "generates valid ics for google_meet location type" do
    booking = bookings(:meet_booking)
    ics = IcsGenerator.new(booking).generate

    assert_match "LOCATION:https://meet.google.com/abc-defg-hij", ics
  end

  test "includes organizer" do
    booking = bookings(:confirmed_one)
    ics = IcsGenerator.new(booking).generate

    assert_match "ORGANIZER", ics
    assert_match booking.schedule_link.created_by.email_address, ics
  end

  test "times are in UTC" do
    booking = bookings(:confirmed_one)
    ics = IcsGenerator.new(booking).generate

    assert_match(/DTSTART[^:]*:.*Z|DTSTART;TZID=UTC:/, ics)
    assert_match(/DTEND[^:]*:.*Z|DTEND;TZID=UTC:/, ics)
  end

  test "includes schedule link description in event description" do
    booking = bookings(:confirmed_one)
    booking.schedule_link.update!(description: "Please bring your laptop")
    booking.update!(invitee_notes: nil)
    ics = IcsGenerator.new(booking).generate

    assert_match "Please bring your laptop", ics
  end

  test "combines schedule link description with invitee notes" do
    booking = bookings(:confirmed_one)
    booking.schedule_link.update!(description: "Bring your laptop")
    booking.update!(invitee_notes: "Looking forward to it")
    ics = IcsGenerator.new(booking).generate
    # ICS format folds long lines — unfold before matching
    unfolded = ics.gsub("\r\n ", "")

    assert_match "Bring your laptop", unfolded
    assert_match "Looking forward to it", unfolded
  end

  test "uses invitee notes alone when no schedule link description" do
    booking = bookings(:confirmed_one)
    booking.schedule_link.update!(description: nil)
    booking.update!(invitee_notes: "Some notes")
    ics = IcsGenerator.new(booking).generate

    assert_match "Some notes", ics
  end

  test "handles nil location gracefully" do
    booking = bookings(:meet_booking)
    booking.update!(meeting_location_url: nil)
    ics = IcsGenerator.new(booking).generate

    assert_match "BEGIN:VEVENT", ics
  end
end
