module CalendarHelper
  DAY_START_HOUR = 7
  DAY_END_HOUR = 20
  HOUR_HEIGHT = 64

  def calendar_hour_labels
    (DAY_START_HOUR...DAY_END_HOUR).map do |hour|
      Time.zone.parse("#{hour}:00").strftime("%-l %p")
    end
  end

  def calendar_block_style(block, day)
    timezone = ActiveSupport::TimeZone[Current.user.timezone]
    start_time = block[:start_time].in_time_zone(timezone)
    end_time = block[:end_time].in_time_zone(timezone)
    day_start = timezone.parse("#{day} #{DAY_START_HOUR}:00")
    day_end = timezone.parse("#{day} #{DAY_END_HOUR}:00")

    clipped_start = [ start_time, day_start ].max
    clipped_end = [ end_time, day_end ].min
    return "display: none;" if clipped_end <= day_start || clipped_start >= day_end

    top_minutes = ((clipped_start - day_start) / 60).to_i
    duration_minutes = [ ((clipped_end - clipped_start) / 60).to_i, 15 ].max

    "top: #{top_minutes * HOUR_HEIGHT / 60}px; height: #{duration_minutes * HOUR_HEIGHT / 60}px;"
  end

  def calendar_grid_height
    (DAY_END_HOUR - DAY_START_HOUR) * HOUR_HEIGHT
  end
end
