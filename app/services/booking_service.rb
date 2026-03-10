class BookingService
  Result = Struct.new(:success?, :booking, :error, keyword_init: true)

  def initialize(schedule_link, params)
    @link = schedule_link
    @params = params
  end

  def call
    booking = nil

    ActiveRecord::Base.transaction do
      # Re-check slot availability inside transaction
      date = Time.parse(@params[:start_time]).in_time_zone(@link.timezone).to_date
      slots = AvailabilityCalculator.new(@link, date).available_slots
      start_time = Time.parse(@params[:start_time]).utc

      unless slots.any? { |s| s[:start_time].to_i == start_time.to_i }
        return Result.new("success?": false, error: "This time slot is no longer available")
      end

      booking = @link.bookings.create!(
        start_time: start_time,
        end_time: Time.parse(@params[:end_time]).utc,
        invitee_name: @params[:invitee_name],
        invitee_email: @params[:invitee_email],
        invitee_timezone: @params[:timezone],
        invitee_notes: @params[:invitee_notes]
      )

      find_or_create_contacts(booking)
    end

    # Create Google Calendar events per connected member (outside transaction, non-blocking)
    create_calendar_events(booking)

    # Invalidate GCal busy caches
    invalidate_caches(booking)

    # Send confirmation email to invitee
    BookingMailer.confirmation(booking).deliver_later

    # Notify hosts
    @link.members.each do |member|
      BookingMailer.host_notification(booking, member).deliver_later
    end

    # Schedule workflow emails
    WorkflowScheduler.new(booking).schedule_all

    Result.new("success?": true, booking: booking)
  rescue ActiveRecord::RecordNotUnique
    Result.new("success?": false, error: "This time slot has just been booked. Please choose another time.")
  rescue ActiveRecord::RecordInvalid => e
    Result.new("success?": false, error: e.record.errors.full_messages.join(", "))
  end

  private

  def create_calendar_events(booking)
    is_meet = @link.meeting_location_type == "google_meet"
    creator = @link.created_by

    connected_members = @link.members.select(&:google_calendar_connected?)
    sorted_members = connected_members.sort_by { |m| m == creator ? 0 : 1 }

    sorted_members.each do |member|
      begin
        service = GoogleCalendarService.new(member)
        attendee_emails = (is_meet && member == creator) ? [ booking.invitee_email ] : []

        result = service.create_event(
          title: "#{@link.meeting_name} with #{booking.invitee_name}",
          start_time: booking.start_time,
          end_time: booking.end_time,
          description: booking.invitee_notes,
          location: is_meet ? booking.meeting_location_url : @link.meeting_location_value,
          add_conference: is_meet && member == creator,
          attendees: attendee_emails
        )

        booking.update!(google_event_id: result[:event_id]) if result[:event_id]

        if is_meet && member == creator && result[:meet_url].present?
          booking.update!(meeting_location_url: result[:meet_url])
        end
      rescue => e
        Rails.logger.error "Failed to create GCal event for member #{member.id}: #{e.message}"
      end
    end
  end

  def find_or_create_contacts(booking)
    @link.members.each do |member|
      contact = member.contacts.find_or_initialize_by(email: booking.invitee_email)
      contact.name = booking.invitee_name
      contact.last_booked_at = Time.current
      contact.total_bookings_count = (contact.total_bookings_count || 0) + 1
      contact.save!
    end

    booking.update!(contact: @link.created_by.contacts.find_by(email: booking.invitee_email))
  end

  def invalidate_caches(booking)
    date = booking.start_time.to_date
    @link.members.each do |member|
      GoogleCalendarService.invalidate_busy_cache(member, date)
    end
  end
end
