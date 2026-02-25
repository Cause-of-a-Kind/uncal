class AvailabilityCalculator
  def initialize(schedule_link, date)
    @link = schedule_link
    @date = date
    @timezone = ActiveSupport::TimeZone[@link.timezone]
  end

  # Returns array of { start_time: Time(UTC), end_time: Time(UTC) }
  def available_slots
    # Step 1: Determine day_of_week in the link's timezone
    # Ruby wday: Sun=0, Mon=1 ... Sat=6
    # App convention: Mon=0, Tue=1 ... Sun=6
    wday = @date.wday
    day_of_week = (wday + 6) % 7

    # Step 2: Reject past dates
    today_in_tz = Time.current.in_time_zone(@timezone).to_date
    return [] if @date < today_in_tz

    # Step 3: Reject beyond max_future_days
    return [] if @date > today_in_tz + @link.max_future_days

    # Step 4: Per member — get free slots
    members = @link.members.to_a
    return [] if members.empty?

    member_free_slots = members.map do |member|
      compute_member_free_slots(member, day_of_week)
    end

    # Step 5: Intersect all members' free slots
    combined = member_free_slots.first
    member_free_slots[1..].each do |slots|
      combined = TimeSlotHelper.intersect_ranges(combined, slots)
    end

    # Steps 6-8: Booking constraints (guarded — Booking model may not exist yet)
    if @link.respond_to?(:bookings)
      bookings = @link.bookings.where(
        "start_time >= ? AND start_time < ?",
        date_start_utc,
        date_end_utc
      )

      if defined?(Booking) && Booking.column_names.include?("status")
        bookings = bookings.where(status: "confirmed")
      end

      # Step 7: max_bookings_per_day check
      if @link.max_bookings_per_day.present? && bookings.count >= @link.max_bookings_per_day
        return []
      end

      # Step 8: Subtract bookings with buffer
      booking_ranges = bookings.map do |b|
        [ b.start_time, b.end_time + @link.buffer_minutes.minutes ]
      end
      combined = TimeSlotHelper.subtract_ranges(combined, booking_ranges)
    end

    # Step 9: Split into slots
    duration = @link.meeting_duration_minutes
    slot_starts = TimeSlotHelper.split_into_slots(combined, duration_minutes: duration)

    # Step 10: Filter out past slots (for today's date)
    now = Time.current
    slot_starts.reject! { |start_time| start_time <= now }

    slot_starts.map do |start_time|
      { start_time: start_time, end_time: start_time + duration.minutes }
    end
  end

  private

  def compute_member_free_slots(member, day_of_week)
    # Step 4a: Get windows for this day
    windows = @link.availability_windows
      .where(user: member, day_of_week: day_of_week)
      .order(:start_time)

    return [] if windows.empty?

    # Step 4b: Convert window times to UTC ranges for the specific date
    utc_ranges = windows.map do |window|
      start_utc = @timezone.parse("#{@date} #{window.start_time.strftime('%H:%M')}").utc
      end_utc = @timezone.parse("#{@date} #{window.end_time.strftime('%H:%M')}").utc
      [ start_utc, end_utc ]
    end

    # Step 4c: Fetch Google Calendar busy times (if connected)
    busy_ranges = fetch_busy_times(member)

    # Step 4d: Subtract busy times from availability
    TimeSlotHelper.subtract_ranges(utc_ranges, busy_ranges)
  end

  def fetch_busy_times(member)
    return [] unless member.google_calendar_connected?

    service = GoogleCalendarService.new(member)
    busy = service.busy_times(@date, @date)
    busy.map { |b| [ b[:start], b[:end] ] }
  rescue GoogleCalendarService::NotConnectedError, GoogleCalendarService::TokenRevokedError
    []
  end

  def date_start_utc
    @timezone.parse("#{@date} 00:00").utc
  end

  def date_end_utc
    @timezone.parse("#{@date} 00:00").utc + 1.day
  end
end
