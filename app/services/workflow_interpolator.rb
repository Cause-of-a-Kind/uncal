class WorkflowInterpolator
  def initialize(booking)
    @booking = booking
    @link = booking.schedule_link
    @timezone = ActiveSupport::TimeZone[@link.timezone]
  end

  def interpolate(text)
    text.gsub(/\{\{(\w+)\}\}/) do |match|
      case $1
      when "invitee_name"     then @booking.invitee_name
      when "invitee_email"    then @booking.invitee_email
      when "meeting_name"     then @link.meeting_name
      when "meeting_date"     then @booking.start_time.in_time_zone(@timezone).strftime("%B %-d, %Y")
      when "meeting_time"     then @booking.start_time.in_time_zone(@timezone).strftime("%-I:%M %p")
      when "meeting_duration" then @link.meeting_duration_minutes.to_s
      when "meeting_location" then @link.meeting_location_value.to_s
      when "host_names"       then @link.members.map(&:name).join(", ")
      else match
      end
    end
  end
end
