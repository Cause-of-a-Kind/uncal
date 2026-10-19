class IcsGenerator
  def initialize(booking, method: :publish)
    @booking = booking
    @link = booking.schedule_link
    @method = method
  end

  def generate
    cal = Icalendar::Calendar.new
    cal.public_send(@method) # METHOD must match the email's text/calendar MIME parameter.
    cal.event do |e|
      # Re-sending or cancelling the same booking must refer to the same event.
      host = Rails.application.config.action_mailer.default_url_options.fetch(:host)
      e.uid = "uncal-booking-#{@booking.id}@#{URI("https://#{host}").host}"
      e.sequence = @method == :cancel ? 1 : 0
      e.status = "CANCELLED" if @method == :cancel
      e.attendee = Icalendar::Values::CalAddress.new("mailto:#{@booking.invitee_email}", rsvp: true) if %i[request cancel].include?(@method)
      e.dtstart = Icalendar::Values::DateTime.new(@booking.start_time.utc, "tzid" => "UTC")
      e.dtend = Icalendar::Values::DateTime.new(@booking.end_time.utc, "tzid" => "UTC")
      e.summary = @link.meeting_name
      e.description = build_description
      e.location = resolve_location
      e.organizer = Icalendar::Values::CalAddress.new("mailto:#{@link.created_by.email_address}", cn: @link.created_by.name)
    end
    cal.to_ical
  end

  private

  def build_description
    parts = []
    parts << @link.description if @link.description.present?
    if @booking.invitee_notes.present?
      parts << "---\nNotes from #{@booking.invitee_name}:\n#{@booking.invitee_notes}"
    end
    parts.join("\n\n").presence
  end

  def resolve_location
    if @link.meeting_location_type == "google_meet"
      @booking.meeting_location_url
    else
      @link.meeting_location_value
    end
  end
end
