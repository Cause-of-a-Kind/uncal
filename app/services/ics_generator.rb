class IcsGenerator
  def initialize(booking)
    @booking = booking
    @link = booking.schedule_link
  end

  def generate
    cal = Icalendar::Calendar.new
    cal.event do |e|
      e.dtstart = Icalendar::Values::DateTime.new(@booking.start_time.utc, "tzid" => "UTC")
      e.dtend = Icalendar::Values::DateTime.new(@booking.end_time.utc, "tzid" => "UTC")
      e.summary = @link.meeting_name
      e.description = @booking.invitee_notes
      e.location = resolve_location
      e.organizer = Icalendar::Values::CalAddress.new("mailto:#{@link.created_by.email_address}", cn: @link.created_by.name)
    end
    cal.to_ical
  end

  private

  def resolve_location
    if @link.meeting_location_type == "google_meet"
      @booking.meeting_location_url
    else
      @link.meeting_location_value
    end
  end
end
